"""Tests for the rent reminder cadence Celery task (T-008).

These run eagerly (``CELERY_TASK_ALWAYS_EAGER`` is set in the test settings), so
calling ``send_rent_reminders()`` exercises the real task body. The actual
WhatsApp/SMS send (T-004) is patched at the ``send_with_fallback`` seam so tests
neither hit the network nor depend on configured credentials.
"""

from __future__ import annotations

from datetime import timedelta
from unittest import mock

import pytest
from django.utils import timezone

from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.enums import Channel, SystemConfigType
from khatir.core.models import SystemConfig
from khatir.rent.enums import RentRequestStatus
from khatir.rent.models import RentRequest
from khatir.rent.tasks import send_rent_reminders
from khatir.rent.tests.factories import RentRequestFactory

pytestmark = pytest.mark.django_db

_SEND_PATH = "khatir.rent.messaging.send_with_fallback"


def _make_request(*, sent_hours_ago: float, status: str = RentRequestStatus.SENT,
                  reminder_count: int = 0) -> RentRequest:
    """A request whose tenant has a reachable phone, sent ``sent_hours_ago`` ago."""
    user: User = UserFactory()  # type: ignore[assignment]
    req: RentRequest = RentRequestFactory(  # type: ignore[assignment]
        status=status, reminder_count=reminder_count
    )
    req.lease.tenant.linked_user = user
    req.lease.tenant.save(update_fields=["linked_user"])
    req.sent_at = timezone.now() - timedelta(hours=sent_hours_ago)
    req.save(update_fields=["sent_at"])
    return req


def _seed_cadence(value: str) -> None:
    # T-009's seed migration already creates this key, so override the value
    # rather than insert a second row (the key is unique).
    SystemConfig.objects.update_or_create(
        key="rent_reminder_cadence_hours",
        defaults={"value": value, "type": SystemConfigType.TEXT},
    )


def test_reminder_at_24h_fires() -> None:
    """A request unpaid for >24h gets exactly one reminder and counters bump."""
    _seed_cadence("24,48")
    req = _make_request(sent_hours_ago=25)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP) as send:
        count = send_rent_reminders()

    assert count == 1
    send.assert_called_once()
    req.refresh_from_db()
    assert req.reminder_count == 1
    assert req.last_reminded_at is not None
    assert req.sent_via == Channel.WHATSAPP.value


def test_not_due_before_threshold() -> None:
    """A request only 10h old is below the 24h threshold — no reminder."""
    _seed_cadence("24,48")
    _make_request(sent_hours_ago=10)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP) as send:
        count = send_rent_reminders()

    assert count == 0
    send.assert_not_called()


def test_stops_after_max() -> None:
    """Once reminder_count reaches the cadence length, no further reminders."""
    _seed_cadence("24,48")
    # Already sent both reminders; far past both thresholds.
    req = _make_request(sent_hours_ago=200, reminder_count=2)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP) as send:
        count = send_rent_reminders()

    assert count == 0
    send.assert_not_called()
    req.refresh_from_db()
    assert req.reminder_count == 2


def test_second_reminder_at_48h() -> None:
    """After the first reminder, the second fires only past the 48h mark."""
    _seed_cadence("24,48")
    req = _make_request(sent_hours_ago=50, reminder_count=1)

    with mock.patch(_SEND_PATH, return_value=Channel.SMS):
        count = send_rent_reminders()

    assert count == 1
    req.refresh_from_db()
    assert req.reminder_count == 2


def test_idempotent_per_window() -> None:
    """A second run in the same window sends nothing (no spam)."""
    _seed_cadence("24,48")
    _make_request(sent_hours_ago=25)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP) as send:
        assert send_rent_reminders() == 1
        assert send_rent_reminders() == 0  # count now 1, still <48h elapsed
    assert send.call_count == 1


def test_cadence_from_config() -> None:
    """The threshold honours config: a 13h cadence fires at 13h, not 24h."""
    _seed_cadence("12")
    _make_request(sent_hours_ago=13)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP):
        assert send_rent_reminders() == 1


def test_default_cadence_when_unseeded() -> None:
    """With no config row the default [24,48] applies."""
    _make_request(sent_hours_ago=25)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP):
        assert send_rent_reminders() == 1


def test_paid_request_skipped() -> None:
    """A verified (paid) request is never reminded."""
    _seed_cadence("24,48")
    _make_request(sent_hours_ago=200, status=RentRequestStatus.VERIFIED)

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP) as send:
        assert send_rent_reminders() == 0
    send.assert_not_called()


def test_missing_contact_does_not_abort_batch() -> None:
    """A request with no tenant contact is logged and skipped, not fatal."""
    _seed_cadence("24,48")
    # Reachable request + an unreachable one (no linked_user).
    ok = _make_request(sent_hours_ago=25)
    bad: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    bad.sent_at = timezone.now() - timedelta(hours=25)
    bad.save(update_fields=["sent_at"])

    with mock.patch(_SEND_PATH, return_value=Channel.WHATSAPP):
        count = send_rent_reminders()

    assert count == 1
    ok.refresh_from_db()
    bad.refresh_from_db()
    assert ok.reminder_count == 1
    assert bad.reminder_count == 0
