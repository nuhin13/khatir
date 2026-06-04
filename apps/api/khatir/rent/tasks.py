"""Rent-collection Celery tasks.

``send_rent_reminders`` is the Beat task (T-008) that re-sends the payment link
to tenants whose rent request is still unpaid past the configured cadence
thresholds, stopping after the max number of reminders so it never spams.
"""

from __future__ import annotations

import json
import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

from khatir.core.config import get_config

from .enums import RentRequestStatus
from .messaging import send_rent_link
from .models import RentRequest

logger = logging.getLogger("khatir.rent")

#: Fallback cadence (hours after send) if ``rent_reminder_cadence_hours`` is
#: unseeded — matches the T-009 default [24, 48].
_DEFAULT_CADENCE_HOURS: list[int] = [24, 48]


def _cadence_hours() -> list[int]:
    """Read the reminder cadence (list of hour thresholds) from config.

    The cadence is persisted as text and may be either a JSON array
    (``"[24, 48]"`` — how T-009's seed writes it) or a plain comma-separated
    string (``"24,48"``). Both are accepted; parse into ints and ignore blanks.
    Falls back to :data:`_DEFAULT_CADENCE_HOURS` when unset or unparseable.
    """
    raw = get_config("rent_reminder_cadence_hours", default=None)
    if raw is None:
        return list(_DEFAULT_CADENCE_HOURS)
    if isinstance(raw, (list, tuple)):
        values: list[object] = list(raw)
    else:
        text = str(raw).strip()
        if text.startswith("["):
            try:
                parsed = json.loads(text)
            except (ValueError, TypeError):
                parsed = []
            values = list(parsed) if isinstance(parsed, (list, tuple)) else []
        else:
            values = [part.strip() for part in text.split(",") if part.strip()]
    try:
        hours = [int(str(v).strip()) for v in values]
    except (ValueError, TypeError):
        hours = []
    return hours or list(_DEFAULT_CADENCE_HOURS)


@shared_task  # type: ignore[untyped-decorator]  # celery has no py.typed marker
def send_rent_reminders() -> int:
    """Re-send the rent link for unpaid requests past their cadence threshold.

    For each ``sent`` (i.e. unpaid) request, the *next* reminder is due once
    ``reminder_count`` reminders have already gone out and ``now`` has passed the
    ``cadence[reminder_count]``-hour mark since the first send. Sends at most one
    reminder per request per run and stops once ``reminder_count`` reaches the
    cadence length (the max). Returns the number of reminders sent.
    """
    cadence = _cadence_hours()
    max_reminders = len(cadence)
    now = timezone.now()
    sent = 0

    unpaid = (
        RentRequest.objects.filter(
            status=RentRequestStatus.SENT,
            sent_at__isnull=False,
            reminder_count__lt=max_reminders,
        )
        .select_related("lease", "lease__tenant", "lease__tenant__linked_user")
        .order_by("pk")
    )
    for request in unpaid:
        sent_at = request.sent_at
        if sent_at is None:  # excluded by the filter, but narrows the type
            continue
        threshold_hours = cadence[request.reminder_count]
        due_at = sent_at + timedelta(hours=threshold_hours)
        if now < due_at:
            continue
        try:
            send_rent_link(request, is_reminder=True)
        except Exception:  # noqa: BLE001 — one bad request must not abort the batch
            logger.exception(
                "rent reminder failed for RentRequest #%s", request.pk
            )
            continue
        sent += 1

    logger.info("rent reminder run sent %s reminder(s)", sent)
    return sent
