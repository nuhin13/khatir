"""Tests for the admin notification broadcast endpoints — EPIC-15.T-007.

Covers (task §1, §11–§14):

* ``GET  /admin/api/notifications``                  — list broadcasts.
* ``POST /admin/api/notifications``                  — compose + dispatch.
* ``GET  /admin/api/notifications/{id}``             — retrieve + embedded deliveries.
* ``POST /admin/api/notifications/{id}/send-test``   — preview send to the admin.

Compose is audited inside the service (``notification.compose``); the send-test
preview is audited in the view (``notification.send_test``). The super+ops role
gate is exercised via the dedicated admin JWT realm. Celery runs eager in the
test settings, so the *now* compose's delivery hand-off is patched at
``services.current_app.send_task`` to keep the test hermetic; the in-app sender
is patched on send-test to assert the preview dispatch.
"""

from __future__ import annotations

from unittest import mock

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole, Channel
from khatir.notifications import services, views
from khatir.notifications.enums import (
    NotificationAudienceType,
    NotificationScheduleType,
    NotificationStatus,
)
from khatir.notifications.models import Notification
from khatir.notifications.tests.factories import (
    NotificationDeliveryFactory,
    NotificationFactory,
)

NOTIFICATIONS_URL = "/admin/api/notifications"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.OPS) -> tuple[APIClient, object]:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client, admin


COMPOSE_PAYLOAD = {
    "audience_type": NotificationAudienceType.ALL,
    "channels": ["inapp"],
    "title_en": "Maintenance window",
    "title_bn": "রক্ষণাবেক্ষণ সময়",
    "body_en": "We will be down at midnight.",
    "body_bn": "মধ্যরাতে বন্ধ থাকবে।",
    "schedule_type": NotificationScheduleType.NOW,
}


# --- list --------------------------------------------------------------------


def test_list_notifications() -> None:
    NotificationFactory(title_en="t007 broadcast")
    client, _ = _auth_client()
    resp = client.get(NOTIFICATIONS_URL)
    assert resp.status_code == 200, resp.content
    body = resp.json()
    rows = body["results"] if isinstance(body, dict) else body
    assert "t007 broadcast" in {row["title_en"] for row in rows}


# --- compose -----------------------------------------------------------------


def test_compose_creates_broadcast(django_user_model) -> None:
    django_user_model.objects.create_user(phone="+8801711100001")
    client, _ = _auth_client(AdminRole.SUPER)
    with mock.patch.object(services.current_app, "send_task"):
        resp = client.post(NOTIFICATIONS_URL, COMPOSE_PAYLOAD, format="json")
    assert resp.status_code == 201, resp.content
    body = resp.json()
    assert body["title_en"] == "Maintenance window"
    assert body["status"] == NotificationStatus.SENDING
    assert body["reach"] == 1
    assert "estimated_cost" in body
    assert Notification.objects.filter(title_en="Maintenance window").exists()


def test_compose_sets_sender_to_acting_admin() -> None:
    client, admin = _auth_client(AdminRole.SUPER)
    with mock.patch.object(services.current_app, "send_task"):
        resp = client.post(NOTIFICATIONS_URL, COMPOSE_PAYLOAD, format="json")
    notification = Notification.objects.get(pk=resp.json()["id"])
    assert notification.sender_id == admin.pk


def test_compose_audited() -> None:
    client, admin = _auth_client(AdminRole.SUPER)
    with mock.patch.object(services.current_app, "send_task"):
        resp = client.post(NOTIFICATIONS_URL, COMPOSE_PAYLOAD, format="json")
    entry = AdminAuditEntry.objects.get(
        action="notification.compose", entity_id=str(resp.json()["id"])
    )
    assert entry.admin_user_id == admin.pk
    assert entry.after_json["audience_type"] == NotificationAudienceType.ALL


def test_compose_invalid_audience_returns_400() -> None:
    client, _ = _auth_client(AdminRole.SUPER)
    payload = {
        **COMPOSE_PAYLOAD,
        "audience_type": NotificationAudienceType.SPECIFIC,
        "audience_filter": {},
    }
    with mock.patch.object(services.current_app, "send_task"):
        resp = client.post(NOTIFICATIONS_URL, payload, format="json")
    assert resp.status_code == 400, resp.content
    assert "detail" in resp.json()


def test_compose_missing_channels_returns_400() -> None:
    client, _ = _auth_client(AdminRole.SUPER)
    payload = {k: v for k, v in COMPOSE_PAYLOAD.items() if k != "channels"}
    resp = client.post(NOTIFICATIONS_URL, payload, format="json")
    assert resp.status_code == 400, resp.content


# --- retrieve + deliveries ---------------------------------------------------


def test_retrieve_embeds_deliveries() -> None:
    notification = NotificationFactory()
    NotificationDeliveryFactory(notification=notification, channel="inapp")
    NotificationDeliveryFactory(notification=notification, channel="sms")
    client, _ = _auth_client()
    resp = client.get(f"{NOTIFICATIONS_URL}/{notification.pk}")
    assert resp.status_code == 200, resp.content
    body = resp.json()
    assert body["id"] == notification.pk
    assert len(body["deliveries"]) == 2
    assert {d["channel"] for d in body["deliveries"]} == {"inapp", "sms"}


# --- send-test ---------------------------------------------------------------


def test_send_test_delivers_to_admin_only() -> None:
    notification = NotificationFactory()
    client, admin = _auth_client(AdminRole.SUPER)
    sender = mock.Mock()
    with mock.patch.object(views, "get_sender", return_value=sender) as get_sender:
        resp = client.post(f"{NOTIFICATIONS_URL}/{notification.pk}/send-test")
    assert resp.status_code == 200, resp.content
    assert resp.json()["recipient"] == admin.email
    get_sender.assert_called_once_with(Channel.INAPP)
    sender.send.assert_called_once()
    # No audience fan-out: counters untouched, no delivery rows created.
    notification.refresh_from_db()
    assert notification.sent_count == 0
    assert notification.deliveries.count() == 0


def test_send_test_audited() -> None:
    notification = NotificationFactory()
    client, admin = _auth_client(AdminRole.SUPER)
    with mock.patch.object(views, "get_sender", return_value=mock.Mock()):
        client.post(f"{NOTIFICATIONS_URL}/{notification.pk}/send-test")
    entry = AdminAuditEntry.objects.get(
        action="notification.send_test", entity_id=str(notification.pk)
    )
    assert entry.admin_user_id == admin.pk
    assert entry.after_json["recipient"] == admin.email


# --- auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(NOTIFICATIONS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_platform_roles_allowed(role: str) -> None:
    client, _ = _auth_client(role)
    assert client.get(NOTIFICATIONS_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_non_platform_roles_denied(role: str) -> None:
    notification = NotificationFactory()
    client, _ = _auth_client(role)
    assert client.get(NOTIFICATIONS_URL).status_code == 403
    with mock.patch.object(services.current_app, "send_task"):
        assert (
            client.post(
                NOTIFICATIONS_URL, COMPOSE_PAYLOAD, format="json"
            ).status_code
            == 403
        )
    assert (
        client.post(
            f"{NOTIFICATIONS_URL}/{notification.pk}/send-test"
        ).status_code
        == 403
    )
