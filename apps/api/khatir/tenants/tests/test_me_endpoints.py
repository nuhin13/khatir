"""API + scoping tests for the tenant self-service ``/api/v1/me/*`` surface (T-002).

Exercises ``GET /me/lease``, ``GET /me/rent`` and ``GET /me/receipts`` through
DRF's ``APIClient`` with a real authenticated tenant. The load-bearing
assertions are the isolation ones: a tenant sees their own lease / schedule /
requests / receipts and **never** another tenant's, an unlinked tenant and a
non-tenant role are denied (403), and the active lease is the current view.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.maintenance.models import MaintenanceRequest
from khatir.rent.tests.factories import PaymentFactory, RentRequestFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


def _tenant_user() -> User:
    created: User = UserFactory(role=Role.TENANT)  # type: ignore[assignment]
    return created


def _authed(user: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=user)
    return api


# --- /me/lease ---------------------------------------------------------------


def test_me_lease_returns_active_lease() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    lease = LeaseFactory(tenant=tenant, status=LeaseStatus.ACTIVE)

    resp = _authed(user).get("/api/v1/me/lease")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(lease.pk)
    assert resp.data["tenant_id"] == str(tenant.pk)


def test_me_lease_404_when_no_active_lease() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    LeaseFactory(tenant=tenant, status=LeaseStatus.ENDED)

    resp = _authed(user).get("/api/v1/me/lease")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_me_lease_never_returns_another_tenants_lease() -> None:
    me = _tenant_user()
    other = _tenant_user()
    my_tenant = TenantFactory(linked_user=me)
    other_tenant = TenantFactory(linked_user=other)
    LeaseFactory(tenant=other_tenant, status=LeaseStatus.ACTIVE)
    my_lease = LeaseFactory(tenant=my_tenant, status=LeaseStatus.ACTIVE)

    resp = _authed(me).get("/api/v1/me/lease")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(my_lease.pk)


def test_me_lease_unlinked_tenant_denied() -> None:
    user = _tenant_user()  # no linked Tenant record

    resp = _authed(user).get("/api/v1/me/lease")

    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_me_lease_non_tenant_role_denied() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    TenantFactory(linked_user=landlord)  # even if linked, role gates it out

    resp = _authed(landlord).get("/api/v1/me/lease")

    assert resp.status_code == status.HTTP_403_FORBIDDEN


# --- /me/rent ----------------------------------------------------------------


def test_me_rent_returns_own_schedule_and_requests() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    lease = LeaseFactory(tenant=tenant, status=LeaseStatus.ACTIVE)
    RentScheduleFactory(lease=lease, period="2026-01")
    RentScheduleFactory(lease=lease, period="2026-02")
    RentRequestFactory(lease=lease, period="2026-01")

    resp = _authed(user).get("/api/v1/me/rent")

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.data["schedule"]) == 2
    assert len(resp.data["requests"]) == 1
    assert resp.data["requests"][0]["lease_id"] == str(lease.pk)


def test_me_rent_excludes_other_tenants_rows() -> None:
    me = _tenant_user()
    other = _tenant_user()
    my_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=me), status=LeaseStatus.ACTIVE
    )
    other_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=other), status=LeaseStatus.ACTIVE
    )
    RentScheduleFactory(lease=my_lease, period="2026-01")
    RentScheduleFactory(lease=other_lease, period="2026-01")
    RentRequestFactory(lease=other_lease, period="2026-01")

    resp = _authed(me).get("/api/v1/me/rent")

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.data["schedule"]) == 1
    assert resp.data["schedule"][0]["lease_id"] == str(my_lease.pk)
    assert resp.data["requests"] == []


def test_me_rent_unlinked_tenant_denied() -> None:
    resp = _authed(_tenant_user()).get("/api/v1/me/rent")
    assert resp.status_code == status.HTTP_403_FORBIDDEN


# --- /me/receipts ------------------------------------------------------------


def test_me_receipts_returns_own_payments() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    lease = LeaseFactory(tenant=tenant, status=LeaseStatus.ACTIVE)
    rr = RentRequestFactory(lease=lease, period="2026-01", amount=Decimal("12000.00"))
    payment = PaymentFactory(
        rent_request=rr,
        receipt_ref="receipts/2026-01.pdf",
        verified_at=datetime.datetime(2026, 1, 6, tzinfo=datetime.UTC),
    )

    resp = _authed(user).get("/api/v1/me/receipts")

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.data) == 1
    row = resp.data[0]
    assert row["id"] == str(payment.pk)
    assert row["lease_id"] == str(lease.pk)
    assert row["period"] == "2026-01"
    assert Decimal(row["amount"]) == Decimal("12000.00")
    assert row["receipt_ref"] == "receipts/2026-01.pdf"


def test_me_receipts_excludes_other_tenants_payments() -> None:
    me = _tenant_user()
    other = _tenant_user()
    my_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=me), status=LeaseStatus.ACTIVE
    )
    other_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=other), status=LeaseStatus.ACTIVE
    )
    mine = PaymentFactory(rent_request=RentRequestFactory(lease=my_lease))
    PaymentFactory(rent_request=RentRequestFactory(lease=other_lease))

    resp = _authed(me).get("/api/v1/me/receipts")

    assert resp.status_code == status.HTTP_200_OK
    assert [r["id"] for r in resp.data] == [str(mine.pk)]


def test_me_receipts_unlinked_tenant_denied() -> None:
    resp = _authed(_tenant_user()).get("/api/v1/me/receipts")
    assert resp.status_code == status.HTTP_403_FORBIDDEN


# --- /me/maintenance ---------------------------------------------------------


def test_me_maintenance_creates_request_on_own_unit() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    lease = LeaseFactory(tenant=tenant, status=LeaseStatus.ACTIVE)

    resp = _authed(user).post(
        "/api/v1/me/maintenance",
        {"description": "Leaking tap", "category": "plumbing"},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["unit_id"] == str(lease.unit_id)
    assert resp.data["lease_id"] == str(lease.pk)
    assert resp.data["category"] == "plumbing"
    assert resp.data["description"] == "Leaking tap"
    assert resp.data["status"] == "open"

    created = MaintenanceRequest.objects.get(pk=resp.data["id"])
    assert created.unit_id == lease.unit_id
    assert created.lease_id == lease.pk


def test_me_maintenance_defaults_category_to_other() -> None:
    user = _tenant_user()
    LeaseFactory(
        tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE
    )

    resp = _authed(user).post(
        "/api/v1/me/maintenance",
        {"description": "Something is broken"},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["category"] == "other"


def test_me_maintenance_404_when_no_active_lease() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    LeaseFactory(tenant=tenant, status=LeaseStatus.ENDED)

    resp = _authed(user).post(
        "/api/v1/me/maintenance",
        {"description": "Leaking tap"},
        format="json",
    )

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert MaintenanceRequest.objects.count() == 0


def test_me_maintenance_always_scoped_to_own_unit() -> None:
    me = _tenant_user()
    my_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=me), status=LeaseStatus.ACTIVE
    )
    other_lease = LeaseFactory(
        tenant=TenantFactory(linked_user=_tenant_user()), status=LeaseStatus.ACTIVE
    )

    resp = _authed(me).post(
        "/api/v1/me/maintenance",
        # A client cannot re-parent the request: there is no unit_id input and
        # the unit is taken from the tenant's own active lease.
        {"description": "x", "unit_id": str(other_lease.unit_id)},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["unit_id"] == str(my_lease.unit_id)
    assert resp.data["unit_id"] != str(other_lease.unit_id)


def test_me_maintenance_requires_description() -> None:
    user = _tenant_user()
    LeaseFactory(
        tenant=TenantFactory(linked_user=user), status=LeaseStatus.ACTIVE
    )

    resp = _authed(user).post("/api/v1/me/maintenance", {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_me_maintenance_unlinked_tenant_denied() -> None:
    resp = _authed(_tenant_user()).post(
        "/api/v1/me/maintenance",
        {"description": "Leaking tap"},
        format="json",
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_me_maintenance_non_tenant_role_denied() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    TenantFactory(linked_user=landlord)

    resp = _authed(landlord).post(
        "/api/v1/me/maintenance",
        {"description": "Leaking tap"},
        format="json",
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN
