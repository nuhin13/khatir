"""Tests for the admin notification-template CRUD endpoints — EPIC-15.T-008.

Covers (task §11–§14): template list/create/retrieve/update; ``key`` and
``trigger_event`` immutable on update; every write audited; super+ops role gate
via the dedicated admin JWT realm.
"""

from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole
from khatir.notifications.models import NotificationTemplate
from khatir.notifications.tests.factories import NotificationTemplateFactory

TEMPLATES_URL = "/admin/api/notification-templates"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.OPS) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- CRUD --------------------------------------------------------------------


def test_create_template() -> None:
    resp = _auth_client(AdminRole.SUPER).post(
        TEMPLATES_URL,
        {
            "key": "t008_welcome",
            "trigger_event": "user.signup",
            "channels": ["inapp", "email"],
            "title_en": "Welcome",
            "title_bn": "স্বাগতম",
            "body_en": "Hello {name}!",
            "body_bn": "হ্যালো {name}!",
            "variables": ["name"],
        },
        format="json",
    )
    assert resp.status_code == 201, resp.content
    body = resp.json()
    assert body["key"] == "t008_welcome"
    assert body["trigger_event"] == "user.signup"
    assert body["active"] is True
    assert NotificationTemplate.objects.filter(key="t008_welcome").exists()


def test_list_templates() -> None:
    NotificationTemplateFactory(key="t008_a")
    resp = _auth_client().get(TEMPLATES_URL)
    assert resp.status_code == 200
    body = resp.json()
    rows = body["results"] if isinstance(body, dict) else body
    assert "t008_a" in {row["key"] for row in rows}


def test_retrieve_template_by_key() -> None:
    template = NotificationTemplateFactory(key="t008_retrieve")
    resp = _auth_client().get(f"{TEMPLATES_URL}/{template.key}")
    assert resp.status_code == 200
    assert resp.json()["key"] == "t008_retrieve"


def test_update_title_and_body() -> None:
    template = NotificationTemplateFactory(key="t008_update", title_en="old")
    resp = _auth_client().patch(
        f"{TEMPLATES_URL}/{template.key}",
        {"title_en": "new title", "body_en": "new body"},
        format="json",
    )
    assert resp.status_code == 200, resp.content
    template.refresh_from_db()
    assert template.title_en == "new title"
    assert template.body_en == "new body"


def test_update_active_flag() -> None:
    template = NotificationTemplateFactory(key="t008_active", active=True)
    resp = _auth_client().patch(
        f"{TEMPLATES_URL}/{template.key}",
        {"active": False},
        format="json",
    )
    assert resp.status_code == 200
    template.refresh_from_db()
    assert template.active is False


# --- Immutable fields --------------------------------------------------------


def test_key_immutable_on_update() -> None:
    template = NotificationTemplateFactory(key="t008_keylock")
    _auth_client().patch(
        f"{TEMPLATES_URL}/{template.key}",
        {"key": "t008_changed", "title_en": "x"},
        format="json",
    )
    template.refresh_from_db()
    assert template.key == "t008_keylock"


def test_trigger_event_immutable_on_update() -> None:
    template = NotificationTemplateFactory(
        key="t008_triglock", trigger_event="rent.due"
    )
    _auth_client().patch(
        f"{TEMPLATES_URL}/{template.key}",
        {"trigger_event": "rent.overdue", "title_en": "x"},
        format="json",
    )
    template.refresh_from_db()
    assert template.trigger_event == "rent.due"


# --- Audit -------------------------------------------------------------------


def test_create_writes_audit_entry() -> None:
    _auth_client(AdminRole.SUPER).post(
        TEMPLATES_URL,
        {
            "key": "t008_audited",
            "trigger_event": "x.y",
            "channels": ["inapp"],
            "title_en": "T",
            "title_bn": "ট",
            "body_en": "B",
            "body_bn": "ব",
        },
        format="json",
    )
    template = NotificationTemplate.objects.get(key="t008_audited")
    entry = (
        AdminAuditEntry.objects.filter(
            action="notification_template.create", entity_id=str(template.pk)
        )
        .order_by("-id")
        .first()
    )
    assert entry is not None
    assert entry.after_json is not None
    assert entry.after_json["key"] == "t008_audited"


def test_update_writes_audit_entry_with_diff() -> None:
    template = NotificationTemplateFactory(key="t008_audit_upd", title_en="old")
    _auth_client().patch(
        f"{TEMPLATES_URL}/{template.key}",
        {"title_en": "fresh"},
        format="json",
    )
    entry = (
        AdminAuditEntry.objects.filter(
            action="notification_template.update", entity_id=str(template.pk)
        )
        .order_by("-id")
        .first()
    )
    assert entry is not None
    assert entry.before_json is not None
    assert entry.after_json is not None
    assert entry.before_json["title_en"] == "old"
    assert entry.after_json["title_en"] == "fresh"


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(TEMPLATES_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_platform_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(TEMPLATES_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_non_platform_roles_denied(role: str) -> None:
    template = NotificationTemplateFactory(key="t008_denied")
    client = _auth_client(role)
    assert client.get(TEMPLATES_URL).status_code == 403
    assert (
        client.patch(
            f"{TEMPLATES_URL}/{template.key}", {"title_en": "x"}, format="json"
        ).status_code
        == 403
    )
