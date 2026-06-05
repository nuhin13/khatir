"""Tests for the audit-log viewer endpoint (EPIC-11.T-011 §12).

Covers: paginated read of the immutable audit ledger, the compliance/super role
gate (ops/support/finance denied), the optional filters (admin_user, action,
entity_type, date range), the denormalized ``actor`` label + before/after diff
payload, and the absence of any write route (read-only by construction).
"""

from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole

pytestmark = pytest.mark.django_db

AUDIT_URL = "/admin/api/audit-log"


def _auth_client(role: str = AdminRole.COMPLIANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _entry(**kwargs: object) -> AdminAuditEntry:
    defaults: dict[str, object] = {"action": "feature_flag.toggle"}
    defaults.update(kwargs)
    return AdminAuditEntry.objects.create(**defaults)


# --- Access control ---------------------------------------------------------


def test_compliance_can_read() -> None:
    _entry()
    resp = _auth_client(AdminRole.COMPLIANCE).get(AUDIT_URL)
    assert resp.status_code == 200
    assert len(resp.json()["results"]) == 1


def test_super_can_read() -> None:
    _entry()
    resp = _auth_client(AdminRole.SUPER).get(AUDIT_URL)
    assert resp.status_code == 200


@pytest.mark.parametrize("role", [AdminRole.OPS, AdminRole.SUPPORT, AdminRole.FINANCE])
def test_non_audit_roles_denied(role: str) -> None:
    resp = _auth_client(role).get(AUDIT_URL)
    assert resp.status_code == 403


def test_anonymous_denied() -> None:
    resp = APIClient().get(AUDIT_URL)
    assert resp.status_code in (401, 403)


# --- Payload shape ----------------------------------------------------------


def test_payload_carries_diff_and_actor() -> None:
    actor = AdminUserFactory(role=AdminRole.OPS, name="Karim Uddin")
    _entry(
        admin_user=actor,
        action="admin_user.disable",
        before_json={"disabled": False},
        after_json={"disabled": True},
        reason="Offboarding",
    )
    row = _auth_client().get(AUDIT_URL).json()["results"][0]
    assert row["actor"] == "Karim Uddin"
    assert row["before_json"] == {"disabled": False}
    assert row["after_json"] == {"disabled": True}
    assert row["reason"] == "Offboarding"


def test_system_actor_label() -> None:
    _entry(admin_user=None, action="system.cron")
    row = _auth_client().get(AUDIT_URL).json()["results"][0]
    assert row["actor"] == "System"


def test_newest_first_ordering() -> None:
    _entry(action="a.first")
    _entry(action="b.second")
    actions = [r["action"] for r in _auth_client().get(AUDIT_URL).json()["results"]]
    assert actions == ["b.second", "a.first"]


# --- Filters ----------------------------------------------------------------


def test_filter_by_action() -> None:
    _entry(action="feature_flag.toggle")
    _entry(action="admin_user.disable")
    body = _auth_client().get(AUDIT_URL, {"action": "admin_user.disable"}).json()
    assert [r["action"] for r in body["results"]] == ["admin_user.disable"]


def test_filter_by_entity_type() -> None:
    _entry(entity_type="accounts.user")
    _entry(entity_type="billing.subscription")
    body = _auth_client().get(AUDIT_URL, {"entity_type": "accounts.user"}).json()
    assert [r["entity_type"] for r in body["results"]] == ["accounts.user"]


def test_filter_by_admin_user() -> None:
    actor = AdminUserFactory(role=AdminRole.OPS)
    _entry(admin_user=actor, action="x.y")
    _entry(admin_user=None, action="system.z")
    body = _auth_client().get(AUDIT_URL, {"admin_user": str(actor.pk)}).json()
    assert [r["action"] for r in body["results"]] == ["x.y"]


def test_filter_system_actor() -> None:
    actor = AdminUserFactory(role=AdminRole.OPS)
    _entry(admin_user=actor, action="x.y")
    _entry(admin_user=None, action="system.z")
    body = _auth_client().get(AUDIT_URL, {"admin_user": "system"}).json()
    assert [r["action"] for r in body["results"]] == ["system.z"]


def test_filter_by_date_range() -> None:
    from datetime import timedelta

    from django.db import connection
    from django.utils import timezone

    old = _entry(action="old.entry")
    # The audit model is immutable (no ORM update); backdate via raw SQL so the
    # date-range filter has an out-of-window row to exclude.
    table = AdminAuditEntry._meta.db_table
    with connection.cursor() as cursor:
        cursor.execute(
            f"UPDATE {table} SET created_at = %s WHERE id = %s",  # noqa: S608
            [timezone.now() - timedelta(days=10), old.pk],
        )
    _entry(action="new.entry")

    cutoff = (timezone.now() - timedelta(days=1)).isoformat()
    body = _auth_client().get(AUDIT_URL, {"from": cutoff}).json()
    assert [r["action"] for r in body["results"]] == ["new.entry"]


# --- Read-only --------------------------------------------------------------


@pytest.mark.parametrize("method", ["post", "put", "patch", "delete"])
def test_no_write_methods(method: str) -> None:
    client = _auth_client()
    resp = getattr(client, method)(AUDIT_URL)
    assert resp.status_code == 405
