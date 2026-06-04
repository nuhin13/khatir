"""API tests for verify / mark-received / reject + receipt PDF (T-007 §12).

Exercises ``/api/v1/rent-requests/{id}/verify|mark-received|reject`` through
DRF's ``APIClient`` with a real authenticated landlord. Verifies that:

* **verify** creates a :class:`Payment` (verified_by/at), stores a receipt PDF,
  moves the request → ``verified`` and the source schedule → ``paid``, and
  writes a ``rent.payment.verify`` audit row;
* **mark-received** does the same with no proof (cash path);
* **reject** moves the request → ``rejected`` with the reason audited and
  creates **no** Payment;
* a settled request cannot be re-settled (409), and foreign requests 404.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.leases.enums import RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.rent.enums import RentRequestStatus
from khatir.rent.models import Payment, RentRequest
from khatir.rent.receipts import render_receipt_pdf

from .factories import PaymentFactory, RentRequestFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/rent-requests"


def _verify(pk: object) -> str:
    return f"{URL}/{pk}/verify"


def _mark_received(pk: object) -> str:
    return f"{URL}/{pk}/mark-received"


def _reject(pk: object) -> str:
    return f"{URL}/{pk}/reject"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


# ── verify ─────────────────────────────────────────────────────────────────────


def test_verify_creates_payment_receipt(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, rent=Decimal("18000.00"))
    schedule = RentScheduleFactory(
        lease=lease,
        period="2026-03",
        amount=Decimal("18000.00"),
        status=RentScheduleStatus.REQUESTED,
    )
    req = RentRequestFactory(
        lease=lease,
        rent_schedule=schedule,
        period="2026-03",
        amount=Decimal("18000.00"),
        status=RentRequestStatus.PROOF_SUBMITTED,
        link_token="tok_verify",
    )

    resp = client.post(_verify(req.pk), {}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == RentRequestStatus.VERIFIED.value

    payment = Payment.objects.get(rent_request=req)
    assert payment.verified_by_id == landlord.pk
    assert payment.verified_at is not None
    assert payment.receipt_ref  # receipt PDF stored
    # Receipt bytes are a valid PDF document.
    assert render_receipt_pdf(req, payment).startswith(b"%PDF")

    schedule.refresh_from_db()
    assert schedule.status == RentScheduleStatus.PAID

    assert AuditEntry.objects.filter(
        action="rent.payment.verify", target_id=str(req.pk)
    ).exists()


def test_verify_already_settled_is_409(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    req = RentRequestFactory(
        lease=lease, status=RentRequestStatus.VERIFIED, link_token="tok_done"
    )
    resp = client.post(_verify(req.pk), {}, format="json")
    assert resp.status_code == status.HTTP_409_CONFLICT


def test_verify_foreign_request_is_404(client: APIClient) -> None:
    other = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    req = RentRequestFactory(lease=other, link_token="tok_foreign")
    resp = client.post(_verify(req.pk), {}, format="json")
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not Payment.objects.filter(rent_request=req).exists()


# ── mark-received (cash) ─────────────────────────────────────────────────────────


def test_mark_received(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    schedule = RentScheduleFactory(
        lease=lease, period="2026-04", status=RentScheduleStatus.REQUESTED
    )
    req = RentRequestFactory(
        lease=lease,
        rent_schedule=schedule,
        period="2026-04",
        status=RentRequestStatus.SENT,
        link_token="tok_cash",
    )

    resp = client.post(_mark_received(req.pk), {}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == RentRequestStatus.VERIFIED.value
    payment = Payment.objects.get(rent_request=req)
    assert payment.receipt_ref
    schedule.refresh_from_db()
    assert schedule.status == RentScheduleStatus.PAID
    assert AuditEntry.objects.filter(
        action="rent.payment.mark_received", target_id=str(req.pk)
    ).exists()


# ── reject ───────────────────────────────────────────────────────────────────────


def test_reject(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    req = RentRequestFactory(
        lease=lease, status=RentRequestStatus.PROOF_SUBMITTED, link_token="tok_rej"
    )

    resp = client.post(
        _reject(req.pk), {"reason": "Transaction id not found."}, format="json"
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == RentRequestStatus.REJECTED.value
    assert not Payment.objects.filter(rent_request=req).exists()
    entry = AuditEntry.objects.get(
        action="rent.payment.reject", target_id=str(req.pk)
    )
    assert entry.after is not None
    assert entry.after["reject_reason"] == "Transaction id not found."


def test_reject_requires_reason(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    req = RentRequestFactory(
        lease=lease, status=RentRequestStatus.PROOF_SUBMITTED, link_token="tok_rej2"
    )
    resp = client.post(_reject(req.pk), {"reason": ""}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert RentRequest.objects.get(pk=req.pk).status == (
        RentRequestStatus.PROOF_SUBMITTED.value
    )


def test_reject_already_settled_is_409(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    req = RentRequestFactory(
        lease=lease, status=RentRequestStatus.VERIFIED, link_token="tok_rej3"
    )
    PaymentFactory(rent_request=req, verified_by=landlord)
    resp = client.post(_reject(req.pk), {"reason": "too late"}, format="json")
    assert resp.status_code == status.HTTP_409_CONFLICT
