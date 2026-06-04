"""Notification delivery Celery tasks — EPIC-15 T-003 (§1, §2).

:func:`deliver_notification` is the fan-out entry point enqueued by the
T-002 compose service (referenced there by name). For one
:class:`~khatir.notifications.models.Notification` it:

#. **Re-resolves the audience** at *send* time (the compose-time reach was only
   a preview) into the matching active customer ``User`` rows.
#. **Fans out** one :func:`deliver_to_recipient` sub-task per
   ``recipient × channel`` so a single slow/failed channel never blocks the
   rest of the broadcast.
#. **Marks the broadcast** ``sent`` once every sub-task has been enqueued (the
   aggregate ``sent_count`` / ``delivered_count`` are then maintained by the
   per-recipient tasks as they complete).

:func:`deliver_to_recipient` performs the actual delivery for one recipient on
one channel: it idempotently creates/updates the
:class:`~khatir.notifications.models.NotificationDelivery` row, renders the
recipient's language variant, calls the EPIC-01
:class:`~khatir.messaging.senders.NotificationSender`, records ``sent`` /
``delivered`` / ``failed``, and bumps the parent's aggregate counts atomically.

The audience resolution mirrors the T-002 compose service so both views of the
audience agree; it is duplicated here (rather than imported) because the compose
helper is private and send-time resolution is a deliberately separate concern.
"""

from __future__ import annotations

import logging
from typing import Any

from celery import shared_task
from django.db import transaction
from django.db.models import F, QuerySet
from django.utils import timezone

from khatir.accounts.models import User
from khatir.core.enums import Channel, Language, Role
from khatir.core.exceptions import UpstreamUnavailableError, ValidationError
from khatir.messaging import get_sender

from .enums import (
    NotificationAudienceType,
    NotificationDeliveryStatus,
    NotificationStatus,
)
from .models import Notification, NotificationDelivery

logger = logging.getLogger("khatir.notifications")

#: Channels that carry no money cost and need no external provider; delivered
#: in-app (console in dev) — also the catch-all for EMAIL until a real provider
#: is registered, so a broadcast never hard-fails on an unconfigured channel.
_INAPP_CHANNELS = frozenset({Channel.INAPP.value, Channel.EMAIL.value})


def _audience_queryset(
    audience_type: str, audience_filter: dict[str, Any]
) -> QuerySet[User]:
    """Re-resolve an audience descriptor to its active ``User`` rows at send time.

    Mirrors the compose-time resolver: only active customer accounts are ever
    targeted. An unknown type or malformed filter yields an *empty* queryset
    here (rather than raising) so a single bad broadcast fails closed without
    aborting the worker — the failure is logged by the caller.
    """
    base = User.objects.filter(is_active=True)

    if audience_type == NotificationAudienceType.ALL:
        return base

    if audience_type in (
        NotificationAudienceType.ROLE,
        NotificationAudienceType.SEGMENT,
    ):
        role = audience_filter.get("role")
        valid_roles = {r.value for r in Role}
        if role in valid_roles:
            return base.filter(role=role)
        return base.none()

    if audience_type == NotificationAudienceType.SPECIFIC:
        ids = audience_filter.get("user_ids")
        if isinstance(ids, list) and ids:
            return base.filter(pk__in=ids)
        return base.none()

    return base.none()


def _render(notification: Notification, language: str) -> tuple[str, str]:
    """Return the ``(title, body)`` variant for the recipient's ``language``."""
    if language == Language.EN.value:
        return notification.title_en, notification.body_en
    return notification.title_bn, notification.body_bn


def _recipient_address(user: User, channel: str) -> str:
    """The provider address for ``user`` on ``channel``.

    The phone number is the login identity and the only contact handle the
    auth ``User`` carries, so it doubles as the WhatsApp/SMS recipient; in-app
    addressing keys off the user id.
    """
    if channel in _INAPP_CHANNELS:
        return str(user.pk)
    return user.phone


@shared_task  # type: ignore[untyped-decorator]  # celery has no py.typed marker
def deliver_notification(notification_id: int) -> int:
    """Fan a broadcast out to one sub-task per recipient × channel.

    Re-resolves the audience, enqueues a :func:`deliver_to_recipient` task for
    every ``(recipient, channel)`` pair, marks the broadcast ``sent``, and
    returns the number of sub-tasks dispatched. A missing notification is a
    no-op (returns 0) so a stale Beat row never crashes the worker.
    """
    try:
        notification = Notification.objects.get(pk=notification_id)
    except Notification.DoesNotExist:
        logger.warning("deliver_notification: notification #%s not found", notification_id)
        return 0

    if notification.status != NotificationStatus.SENDING:
        Notification.objects.filter(pk=notification.pk).update(
            status=NotificationStatus.SENDING
        )

    channels = [str(c) for c in (notification.channels or [])]
    recipients = list(
        _audience_queryset(
            notification.audience_type, dict(notification.audience_filter or {})
        ).values_list("pk", flat=True)
    )

    dispatched = 0
    for user_id in recipients:
        for channel in channels:
            deliver_to_recipient.delay(notification.pk, user_id, channel)
            dispatched += 1

    Notification.objects.filter(pk=notification.pk).update(
        status=NotificationStatus.SENT
    )
    logger.info(
        "deliver_notification #%s fanned out %s sub-task(s) "
        "(%s recipient(s) × %s channel(s))",
        notification.pk,
        dispatched,
        len(recipients),
        len(channels),
    )
    return dispatched


@shared_task  # type: ignore[untyped-decorator]  # celery has no py.typed marker
def deliver_to_recipient(notification_id: int, user_id: int, channel: str) -> str:
    """Deliver one broadcast to one recipient over one channel.

    Idempotently upserts the :class:`NotificationDelivery` row (so a retried
    task never duplicates it), renders the recipient's language variant, calls
    the channel sender, and records the outcome. On success the parent's
    ``sent_count`` (and ``delivered_count`` for synchronously-confirmed
    in-app/email) is bumped; on a sender failure the row is marked ``failed``
    with the error captured. Returns the final delivery status.
    """
    try:
        notification = Notification.objects.get(pk=notification_id)
        user = User.objects.get(pk=user_id)
    except (Notification.DoesNotExist, User.DoesNotExist):
        logger.warning(
            "deliver_to_recipient: notification #%s / user #%s missing",
            notification_id,
            user_id,
        )
        return NotificationDeliveryStatus.FAILED

    delivery, _ = NotificationDelivery.objects.get_or_create(
        notification=notification,
        user=user,
        channel=channel,
        defaults={"status": NotificationDeliveryStatus.QUEUED},
    )

    title, body = _render(notification, user.language)
    message = f"{title}\n\n{body}".strip()
    address = _recipient_address(user, channel)

    # In-app / email deliver synchronously via the console sender, so we can
    # confirm delivery in the same step; remote channels (WhatsApp/SMS) are
    # 'sent' here and confirmed asynchronously by the provider webhook (T-004).
    synchronous = channel in _INAPP_CHANNELS

    try:
        sender_channel = (
            Channel.INAPP if synchronous else Channel(channel)
        )
        sender = get_sender(sender_channel)
        sender.send(address, message, channel=sender_channel)
    except (UpstreamUnavailableError, ValidationError, ValueError) as exc:
        with transaction.atomic():
            NotificationDelivery.objects.filter(pk=delivery.pk).update(
                status=NotificationDeliveryStatus.FAILED,
                error=str(exc),
            )
        logger.warning(
            "delivery #%s to user #%s via %s failed: %s",
            delivery.pk,
            user_id,
            channel,
            exc,
        )
        return NotificationDeliveryStatus.FAILED

    now = timezone.now()
    if synchronous:
        final_status = NotificationDeliveryStatus.DELIVERED
        delivered_at = now
        count_fields = {
            "sent_count": F("sent_count") + 1,
            "delivered_count": F("delivered_count") + 1,
        }
    else:
        final_status = NotificationDeliveryStatus.SENT
        delivered_at = None
        count_fields = {"sent_count": F("sent_count") + 1}

    with transaction.atomic():
        NotificationDelivery.objects.filter(pk=delivery.pk).update(
            status=final_status,
            delivered_at=delivered_at,
            error="",
        )
        Notification.objects.filter(pk=notification.pk).update(**count_fields)

    logger.info(
        "delivery #%s to user #%s via %s -> %s",
        delivery.pk,
        user_id,
        channel,
        final_status,
    )
    return final_status
