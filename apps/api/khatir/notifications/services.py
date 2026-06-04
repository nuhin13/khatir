"""Notification compose + schedule service — EPIC-15 T-002 (§1, §2).

:func:`compose_notification` is the single entry point an admin uses to author a
broadcast. It:

#. **Validates the audience** — ``all`` (no filter), ``role`` (a customer
   :class:`~khatir.core.enums.Role`), ``segment`` (an ``area`` zone), or
   ``specific`` (an explicit list of user ids).
#. **Resolves the reach count** — how many active customer ``User`` rows the
   audience resolves to *right now* (a preview figure; T-003 re-resolves at send
   time).
#. **Estimates cost** — ``reach × Σ per-channel cost`` read from
   ``SystemConfig`` (``whatsapp_cost_per_message`` etc., seeded by T-009;
   defaults to 0 so the service works standalone). ``inapp`` is always free.
#. **Creates the** :class:`~khatir.notifications.models.Notification` record in
   the status implied by the schedule (``sending`` for *now*, ``scheduled`` for
   a future/recurring send).
#. **Dispatches delivery** — *now* enqueues the T-003 ``deliver_notification``
   task immediately; *scheduled* registers a one-off Celery-Beat
   :class:`~django_celery_beat.models.ClockedSchedule`; *recurring* registers a
   :class:`~django_celery_beat.models.CrontabSchedule` from the supplied cron.
#. **Audits the write** via :func:`khatir.admin_portal.audit.admin_audit`.

The delivery task is referenced **by name** (``current_app.send_task``) rather
than imported, so this service does not hard-depend on T-003 being present at
import time (the two tasks build concurrently).
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from celery import current_app
from django.db import transaction
from django.db.models import QuerySet
from django.utils import timezone

from khatir.accounts.models import User
from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.models import AdminUser
from khatir.core.config import get_config
from khatir.core.enums import Channel, Role
from khatir.core.exceptions import ValidationError

from .enums import (
    NotificationAudienceType,
    NotificationScheduleType,
    NotificationStatus,
)
from .models import Notification

logger = logging.getLogger("khatir.notifications")

#: Celery task that fans out delivery (T-003). Referenced by name so this
#: module imports cleanly even before that task module exists.
_DELIVER_TASK = "khatir.notifications.tasks.deliver_notification"

#: ``SystemConfig`` key holding the per-message money cost for each channel.
#: ``inapp`` is intentionally absent — in-app delivery is always free.
_COST_CONFIG_KEYS: dict[str, str] = {
    Channel.WHATSAPP.value: "whatsapp_cost_per_message",
    Channel.SMS.value: "sms_cost_per_message",
    Channel.EMAIL.value: "email_cost_per_message",
}


@dataclass(frozen=True)
class ComposeResult:
    """Outcome of :func:`compose_notification`.

    ``reach`` is the number of recipients the audience resolved to at compose
    time; ``estimated_cost`` is ``reach × Σ per-channel cost``.
    """

    notification: Notification
    reach: int
    estimated_cost: Decimal


def _validate_channels(channels: list[str]) -> list[str]:
    """Return ``channels`` coerced to valid wire values, or raise."""
    if not channels:
        raise ValidationError("At least one channel is required.")
    valid = {c.value for c in Channel}
    cleaned: list[str] = []
    seen: set[str] = set()
    for raw in channels:
        value = raw.value if isinstance(raw, Channel) else str(raw)
        if value not in valid:
            raise ValidationError(f"Unknown channel '{value}'.")
        if value not in seen:
            seen.add(value)
            cleaned.append(value)
    return cleaned


def _audience_queryset(
    audience_type: str, audience_filter: dict[str, Any]
) -> QuerySet[User]:
    """Resolve an audience descriptor to the matching active ``User`` rows.

    Only active customer accounts are ever targeted. Raises
    :class:`ValidationError` for an unknown type or a malformed filter.
    """
    base = User.objects.filter(is_active=True)

    if audience_type == NotificationAudienceType.ALL:
        return base

    if audience_type == NotificationAudienceType.ROLE:
        role = audience_filter.get("role")
        valid_roles = {r.value for r in Role}
        if role not in valid_roles:
            raise ValidationError(
                f"audience_filter.role must be one of {sorted(valid_roles)}."
            )
        return base.filter(role=role)

    if audience_type == NotificationAudienceType.SEGMENT:
        # A segment targets a customer cohort; the only first-class cohort key on
        # ``User`` today is ``role`` (areas live on tenant/property rows, not the
        # auth user). Accept an explicit ``role`` cohort here; unknown segment
        # shapes are rejected rather than silently matching everyone.
        role = audience_filter.get("role")
        if role is not None:
            valid_roles = {r.value for r in Role}
            if role not in valid_roles:
                raise ValidationError(
                    f"audience_filter.role must be one of {sorted(valid_roles)}."
                )
            return base.filter(role=role)
        raise ValidationError(
            "audience_filter for a 'segment' audience must name a 'role' cohort."
        )

    if audience_type == NotificationAudienceType.SPECIFIC:
        ids = audience_filter.get("user_ids")
        if not isinstance(ids, list) or not ids:
            raise ValidationError(
                "audience_filter.user_ids must be a non-empty list for "
                "a 'specific' audience."
            )
        return base.filter(pk__in=ids)

    raise ValidationError(f"Unknown audience_type '{audience_type}'.")


def _channel_cost(channel: str) -> Decimal:
    """Per-message money cost for ``channel`` (0 for in-app / unconfigured)."""
    key = _COST_CONFIG_KEYS.get(channel)
    if key is None:
        return Decimal("0")
    raw = get_config(key, default="0")
    try:
        return Decimal(str(raw))
    except (ArithmeticError, ValueError, TypeError):
        return Decimal("0")


def _estimate_cost(reach: int, channels: list[str]) -> Decimal:
    """``reach × Σ per-channel cost`` — the projected spend for one send."""
    per_recipient = sum((_channel_cost(c) for c in channels), Decimal("0"))
    return per_recipient * reach


def _resolve_schedule_state(
    schedule_type: str, scheduled_at: Any
) -> tuple[str, Any]:
    """Validate the schedule and return ``(notification_status, scheduled_at)``."""
    if schedule_type == NotificationScheduleType.NOW:
        return NotificationStatus.SENDING, None

    if schedule_type == NotificationScheduleType.SCHEDULED:
        if scheduled_at is None:
            raise ValidationError(
                "scheduled_at is required for a 'scheduled' notification."
            )
        if scheduled_at <= timezone.now():
            raise ValidationError("scheduled_at must be in the future.")
        return NotificationStatus.SCHEDULED, scheduled_at

    if schedule_type == NotificationScheduleType.RECURRING:
        return NotificationStatus.SCHEDULED, scheduled_at

    raise ValidationError(f"Unknown schedule_type '{schedule_type}'.")


def _register_clocked(notification: Notification, run_at: Any) -> None:
    """Register a one-off Celery-Beat clocked task to deliver at ``run_at``."""
    from django_celery_beat.models import ClockedSchedule, PeriodicTask

    clocked, _ = ClockedSchedule.objects.get_or_create(clocked_time=run_at)
    PeriodicTask.objects.create(
        name=f"notification-{notification.pk}-clocked",
        task=_DELIVER_TASK,
        clocked=clocked,
        one_off=True,
        args=json.dumps([notification.pk]),
    )


def _register_recurring(
    notification: Notification, cron: dict[str, Any]
) -> None:
    """Register a recurring Celery-Beat crontab task from ``cron``.

    ``cron`` mirrors :class:`~django_celery_beat.models.CrontabSchedule` fields
    (``minute``/``hour``/``day_of_week``/``day_of_month``/``month_of_year``);
    each defaults to ``*``.
    """
    from django_celery_beat.models import CrontabSchedule, PeriodicTask

    schedule, _ = CrontabSchedule.objects.get_or_create(
        minute=str(cron.get("minute", "*")),
        hour=str(cron.get("hour", "*")),
        day_of_week=str(cron.get("day_of_week", "*")),
        day_of_month=str(cron.get("day_of_month", "*")),
        month_of_year=str(cron.get("month_of_year", "*")),
    )
    PeriodicTask.objects.create(
        name=f"notification-{notification.pk}-recurring",
        task=_DELIVER_TASK,
        crontab=schedule,
        args=json.dumps([notification.pk]),
    )


def compose_notification(
    *,
    admin_user: AdminUser | None,
    audience_type: str,
    audience_filter: dict[str, Any] | None,
    channels: list[str],
    content: dict[str, str],
    schedule_type: str = NotificationScheduleType.NOW,
    scheduled_at: Any = None,
    recurrence: dict[str, Any] | None = None,
    ip: str | None = None,
) -> ComposeResult:
    """Compose, persist, and dispatch (or schedule) a broadcast notification.

    ``content`` must carry ``title_en``/``title_bn``/``body_en``/``body_bn``.
    ``recurrence`` is required (a crontab descriptor) when
    ``schedule_type == recurring``. Returns a :class:`ComposeResult` with the
    created notification, its resolved reach, and the estimated cost.

    Validation failures raise :class:`~khatir.core.exceptions.ValidationError`
    before anything is persisted.
    """
    audience_filter = dict(audience_filter or {})
    cleaned_channels = _validate_channels(channels)

    for field in ("title_en", "title_bn", "body_en", "body_bn"):
        if not content.get(field):
            raise ValidationError(f"content.{field} is required.")

    queryset = _audience_queryset(audience_type, audience_filter)
    reach = queryset.count()
    estimated_cost = _estimate_cost(reach, cleaned_channels)

    status, resolved_at = _resolve_schedule_state(schedule_type, scheduled_at)

    if schedule_type == NotificationScheduleType.RECURRING and not recurrence:
        raise ValidationError(
            "recurrence (a crontab descriptor) is required for a "
            "'recurring' notification."
        )

    with transaction.atomic():
        notification = Notification.objects.create(
            sender=admin_user if (admin_user is not None and admin_user.pk) else None,
            audience_type=audience_type,
            audience_filter=audience_filter,
            channels=cleaned_channels,
            title_en=content["title_en"],
            title_bn=content["title_bn"],
            body_en=content["body_en"],
            body_bn=content["body_bn"],
            schedule_type=schedule_type,
            scheduled_at=resolved_at,
            status=status,
        )

        if schedule_type == NotificationScheduleType.NOW:
            # Enqueue delivery once the row is committed so the worker can read it.
            transaction.on_commit(
                lambda: current_app.send_task(_DELIVER_TASK, args=[notification.pk])
            )
        elif schedule_type == NotificationScheduleType.SCHEDULED:
            _register_clocked(notification, resolved_at)
        else:  # RECURRING
            assert recurrence is not None  # noqa: S101 — guarded above
            _register_recurring(notification, recurrence)

        admin_audit(
            admin_user=admin_user,
            action="notification.compose",
            entity=notification,
            after={
                "audience_type": audience_type,
                "channels": cleaned_channels,
                "schedule_type": schedule_type,
                "reach": reach,
                "estimated_cost": str(estimated_cost),
                "status": status,
            },
            ip=ip,
        )

    logger.info(
        "composed notification #%s audience=%s channels=%s reach=%s schedule=%s",
        notification.pk,
        audience_type,
        cleaned_channels,
        reach,
        schedule_type,
    )
    return ComposeResult(
        notification=notification,
        reach=reach,
        estimated_cost=estimated_cost,
    )
