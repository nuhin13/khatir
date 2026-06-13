"""Tests for the enhanced admin audit-log endpoint — EPIC-16.T-002.

Covers (task §11–§13): read-only listing of immutable admin audit entries;
filtering by admin_user / action / entity_type / entity_id / date range;
pagination envelope; the ``?format=csv`` streaming export; and the
compliance+super (``audit`` section) role gate.
"""

from __future__ import annotations

import csv
import datetime as dt
import io

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import (
    AdminAuditEntryFactory,
    AdminUserFactory,
)
from khatir.core.enums import AdminRole

AUDIT_URL = "/admin/api/audit-log"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.COMPLIANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- Listing -----------------------------------------------------------------


def test_list_audit_entries() -> None:
    AdminAuditEntryFactory()
    AdminAuditEntryFactory()
    resp = _auth_client().get(AUDIT_URL)
    assert resp.status_code == 200, resp.content
    body = resp.json()
    assert "results" in body
    assert "pagination" in body
    assert body["pagination"]["count"] == 2


def test_entry_shape_is_read_only_projection() -> None:
    entry = AdminAuditEntryFactory(
        action="feature_flag.toggle",
        entity_type="featureflags.featureflag",
        entity_id="42",
        before_json={"enabled": False},
        after_json={"enabled": True},
        reason="rollout",
    )
    resp = _auth_client().get(AUDIT_URL)
    row = resp.json()["results"][0]
    assert row["id"] == entry.pk
    assert row["admin_user"] == entry.admin_user_id
    assert row["action"] == "feature_flag.toggle"
    assert row["entity_type"] == "featureflags.featureflag"
    assert row["entity_id"] == "42"
    assert row["before_json"] == {"enabled": False}
    assert row["after_json"] == {"enabled": True}
    assert row["reason"] == "rollout"
    assert "created_at" in row


# --- Filters -----------------------------------------------------------------


def test_filter_by_admin_user() -> None:
    target = AdminUserFactory()
    AdminAuditEntryFactory(admin_user=target)
    AdminAuditEntryFactory()  # other admin
    resp = _auth_client().get(AUDIT_URL, {"admin_user": target.pk})
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["admin_user"] == target.pk


def test_filter_by_action() -> None:
    AdminAuditEntryFactory(action="admin_user.disable")
    AdminAuditEntryFactory(action="feature_flag.toggle")
    resp = _auth_client().get(AUDIT_URL, {"action": "admin_user.disable"})
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["action"] == "admin_user.disable"


def test_filter_by_entity_type_and_id() -> None:
    AdminAuditEntryFactory(entity_type="tenants.tenant", entity_id="7")
    AdminAuditEntryFactory(entity_type="tenants.tenant", entity_id="9")
    AdminAuditEntryFactory(entity_type="leases.lease", entity_id="7")
    resp = _auth_client().get(
        AUDIT_URL, {"entity_type": "tenants.tenant", "entity_id": "7"}
    )
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["entity_type"] == "tenants.tenant"
    assert rows[0]["entity_id"] == "7"


def test_filter_by_date_range() -> None:
    now = timezone.now()
    old = AdminAuditEntryFactory()
    recent = AdminAuditEntryFactory()
    # ``created_at`` is auto-set on insert; force values out-of-band (the
    # immutable manager forbids ``.update()``) to span a known range.
    _force_created_at(old, now - dt.timedelta(days=10))
    _force_created_at(recent, now - dt.timedelta(days=1))

    cutoff = (now - dt.timedelta(days=5)).isoformat()
    resp = _auth_client().get(AUDIT_URL, {"date_from": cutoff})
    ids = {row["id"] for row in resp.json()["results"]}
    assert recent.pk in ids
    assert old.pk not in ids

    resp = _auth_client().get(AUDIT_URL, {"date_to": cutoff})
    ids = {row["id"] for row in resp.json()["results"]}
    assert old.pk in ids
    assert recent.pk not in ids


def _force_created_at(entry: AdminAuditEntry, when: dt.datetime) -> None:
    """Set created_at directly in the DB, bypassing the immutable manager."""
    from django.db import connection

    table = AdminAuditEntry._meta.db_table
    with connection.cursor() as cursor:
        cursor.execute(
            f"UPDATE {table} SET created_at = %s WHERE id = %s",  # noqa: S608
            [when.isoformat(), entry.pk],
        )


# --- CSV export --------------------------------------------------------------


def test_csv_export_streams_filtered_rows() -> None:
    AdminAuditEntryFactory(action="admin_user.disable", entity_id="1")
    AdminAuditEntryFactory(action="feature_flag.toggle", entity_id="2")
    resp = _auth_client().get(
        AUDIT_URL, {"format": "csv", "action": "admin_user.disable"}
    )
    assert resp.status_code == 200
    assert resp["Content-Type"] == "text/csv"
    assert "attachment" in resp["Content-Disposition"]
    assert "audit-log.csv" in resp["Content-Disposition"]

    content = b"".join(resp.streaming_content).decode()
    reader = list(csv.reader(io.StringIO(content)))
    header = reader[0]
    assert header[0] == "id"
    assert "action" in header
    data_rows = reader[1:]
    assert len(data_rows) == 1
    action_idx = header.index("action")
    assert data_rows[0][action_idx] == "admin_user.disable"


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(AUDIT_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.COMPLIANCE])
def test_audit_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(AUDIT_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.OPS, AdminRole.FINANCE, AdminRole.SUPPORT]
)
def test_non_audit_roles_denied(role: str) -> None:
    assert _auth_client(role).get(AUDIT_URL).status_code == 403
