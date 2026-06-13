"""API + scoping tests for the in-app pay endpoint (EPIC-19 · T-003).

``POST /api/v1/me/rent/{id}/pay`` lets a logged-in tenant submit payment proof
in-app, feeding the **same** ``submit_payment_proof`` pipeline as the public
web link (EPIC-07 T-006). The load-bearing assertions are the isolation ones:
a tenant can pay only against their own rent requests, another tenant's request
id is a 404 (never reachable), and the proof create + status transition that
result are exactly the existing pipeline's — no duplicated logic.
"""

from __future__ import annotations

import io

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.rent.enums import PaymentProofType, RentRequestStatus
from khatir.rent.models import PaymentProof
from khatir.rent.tests.factories import RentRequestFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


def _tenant_user() -> User:
    created: User = UserFactory(role=Role.TENANT)  # type: ignore[assignment]
    return created


def _authed(user: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=user)
    return api


def _url(pk: object) -> str:
    return f"/api/v1/me/rent/{pk}/pay"


def test_pay_with_txn_id_creates_proof_and_advances(monkeypatch: pytest.MonkeyPatch) -> None:
    user = _tenant_user()
    lease = LeaseFactory(tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, status=RentRequestStatus.SENT)

    resp = _authed(user).post(_url(rr.pk), {"txn_id": "TX123456"}, format="multipart")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["status"] == RentRequestStatus.PROOF_SUBMITTED
    proof = PaymentProof.objects.get(rent_request=rr)
    assert proof.type == PaymentProofType.BKASH_TXN
    assert proof.value == "TX123456"
    assert proof.submitted_at is not None
    rr.refresh_from_db()
    assert rr.status == RentRequestStatus.PROOF_SUBMITTED


def test_pay_with_note_creates_note_proof() -> None:
    user = _tenant_user()
    lease = LeaseFactory(tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, status=RentRequestStatus.SENT)

    resp = _authed(user).post(_url(rr.pk), {"note": "paid in cash"}, format="multipart")

    assert resp.status_code == status.HTTP_201_CREATED
    proof = PaymentProof.objects.get(rent_request=rr)
    assert proof.type == PaymentProofType.NOTE
    assert proof.value == "paid in cash"


def test_pay_with_screenshot_stores_encrypted(monkeypatch: pytest.MonkeyPatch) -> None:
    captured: dict[str, object] = {}

    def fake_store(data: bytes, *, kind: str) -> str:
        captured["kind"] = kind
        captured["len"] = len(data)
        return "proof/abc.enc"

    monkeypatch.setattr("khatir.tenants.me_views.storage.store_encrypted", fake_store)

    user = _tenant_user()
    lease = LeaseFactory(tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, status=RentRequestStatus.SENT)

    upload = io.BytesIO(b"fake-image-bytes")
    upload.name = "proof.png"
    resp = _authed(user).post(_url(rr.pk), {"screenshot": upload}, format="multipart")

    assert resp.status_code == status.HTTP_201_CREATED
    proof = PaymentProof.objects.get(rent_request=rr)
    assert proof.type == PaymentProofType.SCREENSHOT
    assert proof.photo_ref == "proof/abc.enc"
    assert proof.value == ""
    assert captured["kind"] == "proof"


def test_pay_empty_body_rejected() -> None:
    user = _tenant_user()
    lease = LeaseFactory(tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, status=RentRequestStatus.SENT)

    resp = _authed(user).post(_url(rr.pk), {}, format="multipart")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert not PaymentProof.objects.filter(rent_request=rr).exists()


def test_pay_against_other_tenants_request_is_404() -> None:
    me = _tenant_user()
    other = _tenant_user()
    TenantFactory(linked_user=me)  # me has an identity but not this request
    other_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=other), status=LeaseStatus.ACTIVE
    )
    other_rr = RentRequestFactory(lease=other_lease, status=RentRequestStatus.SENT)

    resp = _authed(me).post(_url(other_rr.pk), {"txn_id": "TX"}, format="multipart")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not PaymentProof.objects.filter(rent_request=other_rr).exists()


def test_pay_unknown_request_is_404() -> None:
    user = _tenant_user()
    TenantFactory(linked_user=user)

    resp = _authed(user).post(_url(999999), {"txn_id": "TX"}, format="multipart")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_pay_unlinked_tenant_denied() -> None:
    resp = _authed(_tenant_user()).post(_url(1), {"txn_id": "TX"}, format="multipart")
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_pay_non_tenant_role_denied() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    TenantFactory(linked_user=landlord)

    resp = _authed(landlord).post(_url(1), {"txn_id": "TX"}, format="multipart")

    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_resubmit_does_not_regress_verified_status() -> None:
    user = _tenant_user()
    lease = LeaseFactory(tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, status=RentRequestStatus.VERIFIED)

    resp = _authed(user).post(_url(rr.pk), {"txn_id": "TX"}, format="multipart")

    assert resp.status_code == status.HTTP_201_CREATED
    rr.refresh_from_db()
    assert rr.status == RentRequestStatus.VERIFIED
