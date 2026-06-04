"""Tests for the admin consent-records endpoint — EPIC-16.T-003.

Covers (task §11–§13): read-only listing of consent records; filtering by
user / consent_type / granted-at date range; pagination envelope; and the
compliance+super (``audit`` section) role gate. Admin auth is the dedicated
admin JWT realm.
"""

from __future__ import annotations

import datetime as dt

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from khatir.accounts.tests.factories import UserFactory
from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.core.enums import AdminRole

CONSENT_URL = "/admin/api/consent-records"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.COMPLIANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- Listing -----------------------------------------------------------------


def test_list_consent_records() -> None:
    ConsentRecordFactory()
    ConsentRecordFactory()
    resp = _auth_client().get(CONSENT_URL)
    assert resp.status_code == 200, resp.content
    body = resp.json()
    assert "results" in body
    assert "pagination" in body
    assert body["pagination"]["count"] == 2


def test_record_shape_is_read_only_projection() -> None:
    record = ConsentRecordFactory(consent_type=ConsentType.MARKETING)
    resp = _auth_client().get(CONSENT_URL)
    row = resp.json()["results"][0]
    assert row["id"] == record.pk
    assert row["user"] == record.user_id
    assert row["consent_type"] == ConsentType.MARKETING
    assert "granted_at" in row
    assert "revoked_at" in row
    assert "expires_at" in row


# --- Filters -----------------------------------------------------------------


def test_filter_by_user() -> None:
    target = UserFactory()
    ConsentRecordFactory(user=target)
    ConsentRecordFactory()  # other user
    resp = _auth_client().get(CONSENT_URL, {"user": target.pk})
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["user"] == target.pk


def test_filter_by_consent_type() -> None:
    ConsentRecordFactory(consent_type=ConsentType.MARKETING)
    ConsentRecordFactory(consent_type=ConsentType.PDPA_DATA_COLLECTION)
    resp = _auth_client().get(
        CONSENT_URL, {"consent_type": ConsentType.MARKETING}
    )
    rows = resp.json()["results"]
    assert len(rows) == 1
    assert rows[0]["consent_type"] == ConsentType.MARKETING


def test_filter_by_granted_date_range() -> None:
    now = timezone.now()
    old = ConsentRecordFactory(granted_at=now - dt.timedelta(days=10))
    recent = ConsentRecordFactory(granted_at=now - dt.timedelta(days=1))
    cutoff = (now - dt.timedelta(days=5)).isoformat()
    resp = _auth_client().get(CONSENT_URL, {"granted_from": cutoff})
    ids = {row["id"] for row in resp.json()["results"]}
    assert recent.pk in ids
    assert old.pk not in ids

    cutoff_to = (now - dt.timedelta(days=5)).isoformat()
    resp = _auth_client().get(CONSENT_URL, {"granted_to": cutoff_to})
    ids = {row["id"] for row in resp.json()["results"]}
    assert old.pk in ids
    assert recent.pk not in ids


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(CONSENT_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.COMPLIANCE])
def test_audit_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(CONSENT_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.OPS, AdminRole.FINANCE, AdminRole.SUPPORT]
)
def test_non_audit_roles_denied(role: str) -> None:
    assert _auth_client(role).get(CONSENT_URL).status_code == 403
