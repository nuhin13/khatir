"""Tests for per-recipient delivery tracking — EPIC-15 T-004.

Covers the signed open-tracking token, the open beacon (1×1 pixel) web view,
the provider delivery webhook, and the idempotent state-transition helpers
(:func:`mark_opened` / :func:`confirm_delivered`) they drive.
"""

from __future__ import annotations

import pytest
from django.test import Client

from khatir.notifications import tasks, tracking
from khatir.notifications.enums import NotificationDeliveryStatus
from khatir.notifications.models import Notification
from khatir.notifications.tests.factories import NotificationDeliveryFactory
from khatir.notifications.tracking import InvalidTrackingToken

pytestmark = pytest.mark.django_db

_GIF_MAGIC = b"GIF89a"


# ── signed token ─────────────────────────────────────────────────────────


def test_token_round_trips() -> None:
    delivery = NotificationDeliveryFactory()
    token = tracking.make_token(delivery)
    assert tracking.resolve_token(token).pk == delivery.pk


def test_tampered_token_rejected() -> None:
    delivery = NotificationDeliveryFactory()
    token = tracking.make_token(delivery)
    with pytest.raises(InvalidTrackingToken):
        tracking.resolve_token(token + "x")


def test_garbage_token_rejected() -> None:
    with pytest.raises(InvalidTrackingToken):
        tracking.resolve_token("not-a-token")


def test_unknown_delivery_rejected() -> None:
    delivery = NotificationDeliveryFactory()
    token = tracking.make_token(delivery)
    delivery.delete()
    with pytest.raises(InvalidTrackingToken):
        tracking.resolve_token(token)


# ── confirm_delivered (webhook helper) ─────────────────────────────────────


def test_confirm_advances_sent_to_delivered_and_counts() -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)

    assert tasks.confirm_delivered(delivery.pk) is True

    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.DELIVERED
    assert delivery.delivered_at is not None
    notification: Notification = delivery.notification
    notification.refresh_from_db()
    assert notification.delivered_count == 1


def test_confirm_is_idempotent() -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)

    assert tasks.confirm_delivered(delivery.pk) is True
    assert tasks.confirm_delivered(delivery.pk) is False  # already delivered

    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.delivered_count == 1  # not double-counted


def test_confirm_missing_delivery_is_false() -> None:
    assert tasks.confirm_delivered(999_999) is False


def test_confirm_does_not_regress_opened() -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.OPENED)
    assert tasks.confirm_delivered(delivery.pk) is False
    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.OPENED


# ── mark_opened (beacon helper) ─────────────────────────────────────────────


def test_open_advances_delivered_to_opened_and_counts() -> None:
    delivery = NotificationDeliveryFactory(
        status=NotificationDeliveryStatus.DELIVERED
    )

    assert tasks.mark_opened(delivery.pk) is True

    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.OPENED
    assert delivery.opened_at is not None
    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.opened_count == 1
    # Already-delivered: an open must not re-bump delivered_count.
    assert notification.delivered_count == 0


def test_open_from_sent_backfills_delivered() -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)

    assert tasks.mark_opened(delivery.pk) is True

    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.OPENED
    assert delivery.delivered_at is not None
    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.opened_count == 1
    # Open from 'sent' implies delivery — counted exactly once here.
    assert notification.delivered_count == 1


def test_open_is_idempotent() -> None:
    delivery = NotificationDeliveryFactory(
        status=NotificationDeliveryStatus.DELIVERED
    )

    assert tasks.mark_opened(delivery.pk) is True
    assert tasks.mark_opened(delivery.pk) is False  # already opened

    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.opened_count == 1


def test_open_ignores_failed_delivery() -> None:
    delivery = NotificationDeliveryFactory(
        status=NotificationDeliveryStatus.FAILED
    )
    assert tasks.mark_opened(delivery.pk) is False
    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.FAILED


def test_open_missing_delivery_is_false() -> None:
    assert tasks.mark_opened(999_999) is False


# ── open beacon web view ────────────────────────────────────────────────────


def test_beacon_returns_pixel_and_records_open(client: Client) -> None:
    delivery = NotificationDeliveryFactory(
        status=NotificationDeliveryStatus.DELIVERED
    )
    url = tracking.beacon_path(delivery)

    resp = client.get(url)

    assert resp.status_code == 200
    assert resp["Content-Type"] == "image/gif"
    assert resp.content.startswith(_GIF_MAGIC)
    assert "no-store" in resp["Cache-Control"]
    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.OPENED


def test_beacon_invalid_token_still_returns_pixel(client: Client) -> None:
    resp = client.get("/n/garbage-token/open.gif")
    assert resp.status_code == 200
    assert resp["Content-Type"] == "image/gif"
    assert resp.content.startswith(_GIF_MAGIC)


def test_beacon_reload_does_not_double_count(client: Client) -> None:
    delivery = NotificationDeliveryFactory(
        status=NotificationDeliveryStatus.DELIVERED
    )
    url = tracking.beacon_path(delivery)

    client.get(url)
    client.get(url)

    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.opened_count == 1


# ── delivery webhook ────────────────────────────────────────────────────────


def test_webhook_confirms_delivery(client: Client) -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)
    token = tracking.make_token(delivery)

    resp = client.post(f"/n/{token}/delivered")

    assert resp.status_code == 200
    assert resp.json() == {"confirmed": True}
    delivery.refresh_from_db()
    assert delivery.status == NotificationDeliveryStatus.DELIVERED


def test_webhook_duplicate_is_idempotent(client: Client) -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)
    token = tracking.make_token(delivery)

    first = client.post(f"/n/{token}/delivered")
    second = client.post(f"/n/{token}/delivered")

    assert first.json() == {"confirmed": True}
    assert second.json() == {"confirmed": False}
    notification = Notification.objects.get(pk=delivery.notification_id)
    assert notification.delivered_count == 1


def test_webhook_unknown_token_is_404(client: Client) -> None:
    resp = client.post("/n/garbage/delivered")
    assert resp.status_code == 404


def test_webhook_rejects_get(client: Client) -> None:
    delivery = NotificationDeliveryFactory(status=NotificationDeliveryStatus.SENT)
    token = tracking.make_token(delivery)
    resp = client.get(f"/n/{token}/delivered")
    assert resp.status_code == 405
