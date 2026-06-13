"""Tests for the PDPA data-request queue endpoints — EPIC-16.T-004.

Covers (task §11–§13): paginated listing of data requests; filtering by
status / type / sla bucket; the compliance+super (``audit`` section) role gate;
the process action (approve export, approve delete, reject) with mandatory
reject reason, ``handled_by`` / ``completed_at`` stamping, status transitions,
admin-audit emission, and the not-pending / not-found conflict paths. Admin
auth is the dedicated admin JWT realm.
"""

from __future__ import annotations

import datetime as dt

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.compliance.enums import DataRequestStatus, DataRequestType
from khatir.compliance.models import DataRequest
from khatir.compliance.tests.factories import DataRequestFactory
from khatir.core.enums import AdminRole

LIST_URL = "/admin/api/data-requests"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.COMPLIANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _process_url(pk: int) -> str:
    return f"{LIST_URL}/{pk}/process"


# --- Listing -----------------------------------------------------------------


def test_list_data_requests() -> None:
    DataRequestFactory()
    DataRequestFactory()
    resp = _auth_client().get(LIST_URL)
    assert resp.status_code == 200, resp.content
    body = resp.json()
    assert "results" in body
    assert "pagination" in body
    assert body["pagination"]["count"] == 2


def test_row_shape_includes_sla_state() -> None:
    req = DataRequestFactory(
        request_type=DataRequestType.DELETE,
        sla_due=timezone.now().date() + dt.timedelta(days=60),
    )
    row = _auth_client().get(LIST_URL).json()["results"][0]
    assert row["id"] == req.pk
    assert row["user"] == req.user_id
    assert row["request_type"] == DataRequestType.DELETE
    assert row["status"] == DataRequestStatus.PENDING
    assert row["sla_state"] == "on_track"
    assert "sla_due" in row
    assert "handled_by" in row


def test_filter_by_status() -> None:
    DataRequestFactory(status=DataRequestStatus.PENDING)
    DataRequestFactory(status=DataRequestStatus.COMPLETED)
    resp = _auth_client().get(LIST_URL, {"status": DataRequestStatus.COMPLETED})
    body = resp.json()
    assert body["pagination"]["count"] == 1
    assert body["results"][0]["status"] == DataRequestStatus.COMPLETED


def test_filter_by_type() -> None:
    DataRequestFactory(request_type=DataRequestType.EXPORT)
    DataRequestFactory(request_type=DataRequestType.DELETE)
    resp = _auth_client().get(LIST_URL, {"type": DataRequestType.DELETE})
    body = resp.json()
    assert body["pagination"]["count"] == 1
    assert body["results"][0]["request_type"] == DataRequestType.DELETE


def test_filter_by_sla_buckets() -> None:
    today = timezone.now().date()
    overdue = DataRequestFactory(sla_due=today - dt.timedelta(days=1))
    due_soon = DataRequestFactory(sla_due=today + dt.timedelta(days=3))
    on_track = DataRequestFactory(sla_due=today + dt.timedelta(days=60))
    client = _auth_client()

    assert _ids(client.get(LIST_URL, {"sla": "overdue"})) == {overdue.pk}
    assert _ids(client.get(LIST_URL, {"sla": "due_soon"})) == {due_soon.pk}
    assert _ids(client.get(LIST_URL, {"sla": "on_track"})) == {on_track.pk}


def _ids(resp: object) -> set[int]:
    return {row["id"] for row in resp.json()["results"]}  # type: ignore[attr-defined]


# --- Role gate ---------------------------------------------------------------


def test_requires_auth() -> None:
    DataRequestFactory()
    resp = APIClient().get(LIST_URL)
    assert resp.status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.OPS, AdminRole.FINANCE, AdminRole.SUPPORT])
def test_non_compliance_roles_forbidden(role: str) -> None:
    DataRequestFactory()
    resp = _auth_client(role).get(LIST_URL)
    assert resp.status_code == 403


@pytest.mark.parametrize("role", [AdminRole.COMPLIANCE, AdminRole.SUPER])
def test_compliance_and_super_allowed(role: str) -> None:
    DataRequestFactory()
    resp = _auth_client(role).get(LIST_URL)
    assert resp.status_code == 200


# --- Process: approve --------------------------------------------------------


def test_approve_export_completes_and_audits() -> None:
    req = DataRequestFactory(request_type=DataRequestType.EXPORT)
    resp = _auth_client().post(_process_url(req.pk), {"action": "approve"})
    assert resp.status_code == 200, resp.content
    req.refresh_from_db()
    assert req.status == DataRequestStatus.COMPLETED
    assert req.completed_at is not None
    assert req.handled_by is not None
    entry = AdminAuditEntry.objects.get(action="data_request.approve_export")
    assert entry.entity_type == "compliance.datarequest"
    assert entry.entity_id == str(req.pk)
    assert entry.after_json["export_package"] == "queued"


def test_approve_delete_moves_to_processing() -> None:
    req = DataRequestFactory(request_type=DataRequestType.DELETE)
    resp = _auth_client().post(_process_url(req.pk), {"action": "approve"})
    assert resp.status_code == 200, resp.content
    req.refresh_from_db()
    assert req.status == DataRequestStatus.PROCESSING
    assert req.handled_by is not None
    entry = AdminAuditEntry.objects.get(action="data_request.approve_delete")
    assert entry.after_json["erasure"] == "queued"


# --- Process: reject ---------------------------------------------------------


def test_reject_requires_reason() -> None:
    req = DataRequestFactory()
    resp = _auth_client().post(_process_url(req.pk), {"action": "reject"})
    assert resp.status_code == 400
    req.refresh_from_db()
    assert req.status == DataRequestStatus.PENDING


def test_reject_with_reason_marks_rejected_and_audits() -> None:
    req = DataRequestFactory()
    resp = _auth_client().post(
        _process_url(req.pk), {"action": "reject", "reason": "Unverified subject"}
    )
    assert resp.status_code == 200, resp.content
    req.refresh_from_db()
    assert req.status == DataRequestStatus.REJECTED
    assert req.completed_at is not None
    entry = AdminAuditEntry.objects.get(action="data_request.reject")
    assert entry.reason == "Unverified subject"


# --- Process: conflict / not found -------------------------------------------


def test_process_already_resolved_is_conflict() -> None:
    req = DataRequestFactory(status=DataRequestStatus.COMPLETED)
    resp = _auth_client().post(_process_url(req.pk), {"action": "approve"})
    assert resp.status_code == 409


def test_process_missing_is_not_found() -> None:
    resp = _auth_client().post(_process_url(999999), {"action": "approve"})
    assert resp.status_code == 404


def test_process_role_gated() -> None:
    req = DataRequestFactory()
    resp = _auth_client(AdminRole.OPS).post(_process_url(req.pk), {"action": "approve"})
    assert resp.status_code == 403
    req.refresh_from_db()
    assert req.status == DataRequestStatus.PENDING


def test_no_double_process_via_service_guard() -> None:
    # A second process attempt after the first must conflict, not re-audit.
    req = DataRequestFactory(request_type=DataRequestType.EXPORT)
    client = _auth_client()
    first = client.post(_process_url(req.pk), {"action": "approve"})
    assert first.status_code == 200
    second = client.post(_process_url(req.pk), {"action": "approve"})
    assert second.status_code == 409
    assert (
        DataRequest.objects.get(pk=req.pk).status == DataRequestStatus.COMPLETED
    )
    assert AdminAuditEntry.objects.filter(
        action="data_request.approve_export", entity_id=str(req.pk)
    ).count() == 1
