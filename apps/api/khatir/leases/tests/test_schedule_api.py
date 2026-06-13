"""API tests for the read-only schedule + unit current-lease endpoints (T-004 §12).

Covers ``GET /api/v1/leases/{id}/schedule`` (chronological, scoped) and
``GET /api/v1/units/{id}/lease`` (the single active lease + tenant summary, or
**404** when the unit has no active lease). Both endpoints are scoped through
``for_user`` so a foreign lease/unit resolves to 404, never 403 (T-004 §15).
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
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.tests.factories import TenantFactory

from .factories import LeaseFactory, RentScheduleFactory

pytestmark = pytest.mark.django_db

LEASES_URL = "/api/v1/leases"
UNITS_URL = "/api/v1/units"


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


# ── GET /leases/{id}/schedule ─────────────────────────────────────────────────


def test_schedule_list(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)
    # Insert out of chronological order — the endpoint must still sort by period.
    RentScheduleFactory(
        lease=lease,
        period="2026-03",
        due_date=datetime.date(2026, 3, 5),
        amount=Decimal("15000.00"),
    )
    RentScheduleFactory(
        lease=lease,
        period="2026-01",
        due_date=datetime.date(2026, 1, 5),
        amount=Decimal("15000.00"),
    )
    RentScheduleFactory(
        lease=lease,
        period="2026-02",
        due_date=datetime.date(2026, 2, 5),
        amount=Decimal("15000.00"),
    )

    resp = client.get(f"{LEASES_URL}/{lease.pk}/schedule")

    assert resp.status_code == status.HTTP_200_OK
    periods = [row["period"] for row in resp.data]
    assert periods == ["2026-01", "2026-02", "2026-03"]
    first = resp.data[0]
    assert first["lease_id"] == str(lease.pk)
    assert first["amount"] == "15000.00"
    assert first["status"] == "pending"


def test_schedule_empty(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.DRAFT)

    resp = client.get(f"{LEASES_URL}/{lease.pk}/schedule")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data == []


def test_schedule_foreign_lease_404(client: APIClient) -> None:
    other = LeaseFactory(status=LeaseStatus.ACTIVE)
    RentScheduleFactory(lease=other)

    resp = client.get(f"{LEASES_URL}/{other.pk}/schedule")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_schedule_requires_auth() -> None:
    lease = LeaseFactory(status=LeaseStatus.ACTIVE)
    resp = APIClient().get(f"{LEASES_URL}/{lease.pk}/schedule")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


# ── GET /units/{id}/lease ─────────────────────────────────────────────────────


def test_unit_current_lease(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    tenant = TenantFactory(name="Karim Mia")
    lease = LeaseFactory(
        landlord=landlord, unit=unit, tenant=tenant, status=LeaseStatus.ACTIVE
    )

    resp = client.get(f"{UNITS_URL}/{unit.pk}/lease")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(lease.pk)
    assert resp.data["unit_id"] == str(unit.pk)
    assert resp.data["status"] == LeaseStatus.ACTIVE.value
    # Embedded tenant summary.
    assert resp.data["tenant"]["id"] == str(tenant.pk)
    assert resp.data["tenant"]["name"] == "Karim Mia"
    assert "nid_number_masked" in resp.data["tenant"]
    # The full NID is never exposed in the summary.
    assert "nid_number" not in resp.data["tenant"]


def test_unit_current_lease_ignores_non_active(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    # Only a draft + a terminated lease exist — neither is "current".
    LeaseFactory(landlord=landlord, unit=unit, status=LeaseStatus.DRAFT)
    LeaseFactory(landlord=landlord, unit=unit, status=LeaseStatus.TERMINATED)

    resp = client.get(f"{UNITS_URL}/{unit.pk}/lease")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_unit_current_lease_none_404(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))

    resp = client.get(f"{UNITS_URL}/{unit.pk}/lease")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_unit_current_lease_foreign_unit_404(client: APIClient) -> None:
    # A foreign unit (different landlord) with an active lease is invisible.
    other_unit = UnitFactory()
    LeaseFactory(unit=other_unit, status=LeaseStatus.ACTIVE)

    resp = client.get(f"{UNITS_URL}/{other_unit.pk}/lease")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_unit_current_lease_requires_auth() -> None:
    unit = UnitFactory()
    resp = APIClient().get(f"{UNITS_URL}/{unit.pk}/lease")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
