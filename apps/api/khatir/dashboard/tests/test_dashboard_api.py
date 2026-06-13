"""API tests for the dashboard endpoint (EPIC-09 · T-002 §12).

Exercises ``GET /api/v1/dashboard`` through DRF's ``APIClient`` with a real
authenticated landlord. Covers the full response shape (every metric present),
owner-scoping (a second landlord's data never leaks), the ``months`` query
param (and its ``SystemConfig`` default), per-user short caching, and that the
endpoint refuses an unauthenticated caller.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.cache import cache
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.properties.enums import UnitStatus
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/dashboard"


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    cache.clear()


@pytest.fixture
def landlord() -> User:
    return UserFactory(role=Role.LANDLORD)  # type: ignore[return-value]


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _unit(owner: User, *, status: str = UnitStatus.OCCUPIED) -> object:
    building = BuildingFactory(owner=owner)
    return UnitFactory(building=building, status=status)


def _lease(owner: User, unit: object) -> object:
    return LeaseFactory(landlord=owner, unit=unit, status=LeaseStatus.ACTIVE)


_EXPECTED_KEYS = {
    "total_collected",
    "total_pending",
    "total_overdue",
    "collection_rate",
    "occupied_units",
    "total_units",
    "occupancy_rate",
    "total_income",
    "total_expense",
    "net",
    "late_payer_count",
    "monthly_series",
    "top_expense_categories",
}


def test_dashboard_response(client: APIClient, landlord: User) -> None:
    """Every metric is present and reflects the landlord's own data."""
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease,
        period="2026-05",
        amount=Decimal("10000.00"),
        status=RentScheduleStatus.PAID,
    )
    RentScheduleFactory(
        lease=lease,
        period="2026-06",
        amount=Decimal("10000.00"),
        status=RentScheduleStatus.OVERDUE,
    )

    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert set(body) == _EXPECTED_KEYS
    assert body["total_collected"] == "10000.00"
    assert body["total_overdue"] == "10000.00"
    assert body["collection_rate"] == 50.0
    assert body["total_units"] == 1
    assert body["occupied_units"] == 1
    assert body["late_payer_count"] == 1
    assert isinstance(body["monthly_series"], list)
    assert isinstance(body["top_expense_categories"], list)


def test_scoped(client: APIClient, landlord: User) -> None:
    """A second landlord's records never appear in the caller's dashboard."""
    other = UserFactory(role=Role.LANDLORD)
    other_unit = _unit(other)
    other_lease = _lease(other, other_unit)
    RentScheduleFactory(
        lease=other_lease,
        period="2026-05",
        amount=Decimal("99999.00"),
        status=RentScheduleStatus.PAID,
    )

    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["total_collected"] == "0.00"
    assert body["total_units"] == 0


def test_months_param(client: APIClient) -> None:
    """The ``months`` query param controls the time-series length."""
    resp = client.get(URL, {"months": 3})

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.json()["monthly_series"]) == 3


def test_months_default_from_config(client: APIClient) -> None:
    """Without the param, the series length is the seeded config default (6)."""
    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.json()["monthly_series"]) == 6


def test_invalid_months_falls_back_to_default(client: APIClient) -> None:
    """A non-integer ``months`` falls back to the config default rather than 500."""
    resp = client.get(URL, {"months": "abc"})

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.json()["monthly_series"]) == 6


def test_cached_per_user(client: APIClient, landlord: User) -> None:
    """The payload is cached for the user — a later write is not seen until TTL."""
    first = client.get(URL).json()
    assert first["total_collected"] == "0.00"

    # Add paid rent *after* the first (cached) read.
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease,
        period="2026-05",
        amount=Decimal("4321.00"),
        status=RentScheduleStatus.PAID,
    )

    cached = client.get(URL).json()
    assert cached["total_collected"] == "0.00"  # served from cache

    cache.clear()
    fresh = client.get(URL).json()
    assert fresh["total_collected"] == "4321.00"


def test_requires_auth() -> None:
    """An unauthenticated caller is rejected."""
    resp = APIClient().get(URL)
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_tenant_role_forbidden() -> None:
    """A tenant role cannot read the landlord dashboard."""
    tenant = UserFactory(role=Role.TENANT)
    api = APIClient()
    api.force_authenticate(user=tenant)

    resp = api.get(URL)
    assert resp.status_code == status.HTTP_403_FORBIDDEN
