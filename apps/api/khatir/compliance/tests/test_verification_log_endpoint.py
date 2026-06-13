"""Tests for the admin verification-logs endpoint — EPIC-17.T-009.

Covers (task §11–§14): read-only listing of verification events in the
EPIC-16 compliance console; filtering by tenant / requested_by / result /
created-at date range; pagination envelope; the compliance+super (``audit``
section) role gate; and — critically — that **no raw EC data** (and not even
the opaque ``provider_ref`` vendor token) ever leaves through this endpoint.
"""

from __future__ import annotations

import datetime as dt

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from khatir.accounts.tests.factories import UserFactory
from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole
from khatir.tenants.tests.factories import TenantFactory
from khatir.verification.enums import VerificationResult
from khatir.verification.tests.factories import VerificationLogFactory

VERIFICATION_URL = "/admin/api/verification-logs"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.COMPLIANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- Listing -----------------------------------------------------------------


def test_list_verification_logs() -> None:
    VerificationLogFactory()
    VerificationLogFactory()
    resp = _auth_client().get(VERIFICATION_URL)
    assert resp.status_code == 200, resp.content
    body = resp.json()
    assert "results" in body
    assert "pagination" in body
    assert body["pagination"]["count"] == 2


def test_row_shape_is_read_only_projection() -> None:
    log = VerificationLogFactory(result=VerificationResult.MATCHED)
    resp = _auth_client().get(VERIFICATION_URL)
    row = resp.json()["results"][0]
    assert row["id"] == log.pk
    assert row["tenant"] == log.tenant_id
    assert row["requested_by"] == log.requested_by_id
    assert row["result"] == VerificationResult.MATCHED
    assert "created_at" in row


def test_no_raw_ec_data_or_provider_ref_exposed() -> None:
    """The compliance viewer surfaces result + date + who only — no raw data."""
    VerificationLogFactory(provider_ref="ec-secret-token-123")
    resp = _auth_client().get(VERIFICATION_URL)
    row = resp.json()["results"][0]
    assert set(row.keys()) == {"id", "tenant", "requested_by", "result", "created_at"}
    # opaque vendor token must never reach the compliance console.
    assert "provider_ref" not in row
    assert "ec-secret-token-123" not in resp.content.decode()
    # no raw EC payload field names ever present.
    for forbidden in ("name", "dob", "address", "photo", "nid", "nid_number"):
        assert forbidden not in row


# --- Filters -----------------------------------------------------------------


def test_filter_by_tenant() -> None:
    target = TenantFactory()
    VerificationLogFactory(tenant=target)
    VerificationLogFactory()  # other tenant
    resp = _auth_client().get(VERIFICATION_URL, {"tenant": target.pk})
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["tenant"] == target.pk


def test_filter_by_requested_by() -> None:
    target = UserFactory()
    VerificationLogFactory(requested_by=target)
    VerificationLogFactory()  # other user
    resp = _auth_client().get(VERIFICATION_URL, {"requested_by": target.pk})
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["requested_by"] == target.pk


def test_filter_by_result() -> None:
    VerificationLogFactory(result=VerificationResult.MATCHED)
    VerificationLogFactory(result=VerificationResult.NOT_MATCHED)
    resp = _auth_client().get(
        VERIFICATION_URL, {"result": VerificationResult.NOT_MATCHED}
    )
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["result"] == VerificationResult.NOT_MATCHED


def test_filter_by_created_date_range() -> None:
    now = timezone.now()
    old = VerificationLogFactory()
    recent = VerificationLogFactory()
    VerificationLog = type(old)  # noqa: N806
    VerificationLog.objects.filter(pk=old.pk).update(
        created_at=now - dt.timedelta(days=10)
    )
    VerificationLog.objects.filter(pk=recent.pk).update(
        created_at=now - dt.timedelta(days=1)
    )
    cutoff = (now - dt.timedelta(days=5)).isoformat()

    resp = _auth_client().get(VERIFICATION_URL, {"date_from": cutoff})
    ids = {row["id"] for row in resp.json()["results"]}
    assert recent.pk in ids
    assert old.pk not in ids

    resp = _auth_client().get(VERIFICATION_URL, {"date_to": cutoff})
    ids = {row["id"] for row in resp.json()["results"]}
    assert old.pk in ids
    assert recent.pk not in ids


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(VERIFICATION_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.COMPLIANCE])
def test_audit_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(VERIFICATION_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.OPS, AdminRole.FINANCE, AdminRole.SUPPORT]
)
def test_non_audit_roles_denied(role: str) -> None:
    assert _auth_client(role).get(VERIFICATION_URL).status_code == 403
