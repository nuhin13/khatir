"""API tests for the portfolio aggregation endpoint (T-005 §12).

Exercises ``GET /api/v1/portfolio`` through DRF's ``APIClient`` with a real
authenticated landlord. Verifies the per-building rollups (unit counts,
occupancy breakdown, rent sum), the top-level ``totals`` object, that the
aggregation is scoped via ``for_user`` (a foreign landlord's building never
leaks in), that soft-deleted units are excluded, that the math is done in the DB
(no N+1 — one query for the buildings), and the auth/role gate.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.properties.enums import UnitStatus

from .factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db

PORTFOLIO_URL = "/api/v1/portfolio"


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


# ── counts / occupancy / rent ─────────────────────────────────────────────────


def test_portfolio_counts(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    UnitFactory.create_batch(2, building=building, status=UnitStatus.OCCUPIED)
    UnitFactory(building=building, status=UnitStatus.VACANT)
    UnitFactory(building=building, status=UnitStatus.MAINTENANCE)

    resp = client.get(PORTFOLIO_URL)

    assert resp.status_code == status.HTTP_200_OK
    row = resp.data["buildings"][0]
    assert row["id"] == str(building.pk)
    assert row["total_units"] == 4


def test_portfolio_occupancy(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    UnitFactory.create_batch(3, building=building, status=UnitStatus.OCCUPIED)
    UnitFactory.create_batch(2, building=building, status=UnitStatus.VACANT)
    UnitFactory(building=building, status=UnitStatus.MAINTENANCE)

    resp = client.get(PORTFOLIO_URL)

    row = resp.data["buildings"][0]
    assert row["occupied"] == 3
    assert row["vacant"] == 2
    assert row["maintenance"] == 1


def test_portfolio_rent_sum(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    UnitFactory(building=building, rent=Decimal("10000.00"))
    UnitFactory(building=building, rent=Decimal("12500.50"))

    resp = client.get(PORTFOLIO_URL)

    row = resp.data["buildings"][0]
    assert Decimal(row["total_rent"]) == Decimal("22500.50")


def test_empty_building_zeroed(client: APIClient, landlord: User) -> None:
    BuildingFactory(owner=landlord)  # no units

    resp = client.get(PORTFOLIO_URL)

    row = resp.data["buildings"][0]
    assert row["total_units"] == 0
    assert row["occupied"] == 0
    assert row["vacant"] == 0
    assert row["maintenance"] == 0
    assert Decimal(row["total_rent"]) == Decimal("0.00")


def test_soft_deleted_units_excluded(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    UnitFactory(building=building, status=UnitStatus.OCCUPIED, rent=Decimal("9000.00"))
    gone = UnitFactory(
        building=building, status=UnitStatus.OCCUPIED, rent=Decimal("5000.00")
    )
    gone.delete()  # soft delete

    resp = client.get(PORTFOLIO_URL)

    row = resp.data["buildings"][0]
    assert row["total_units"] == 1
    assert row["occupied"] == 1
    assert Decimal(row["total_rent"]) == Decimal("9000.00")


# ── totals ─────────────────────────────────────────────────────────────────────


def test_portfolio_totals(client: APIClient, landlord: User) -> None:
    a = BuildingFactory(owner=landlord)
    b = BuildingFactory(owner=landlord)
    UnitFactory(building=a, status=UnitStatus.OCCUPIED, rent=Decimal("10000.00"))
    UnitFactory(building=a, status=UnitStatus.VACANT, rent=Decimal("8000.00"))
    UnitFactory(building=b, status=UnitStatus.OCCUPIED, rent=Decimal("15000.00"))
    UnitFactory(building=b, status=UnitStatus.MAINTENANCE, rent=Decimal("0.00"))

    resp = client.get(PORTFOLIO_URL)

    totals = resp.data["totals"]
    assert totals["buildings"] == 2
    assert totals["total_units"] == 4
    assert totals["occupied"] == 2
    assert totals["vacant"] == 1
    assert totals["maintenance"] == 1
    assert Decimal(totals["total_rent"]) == Decimal("33000.00")


def test_empty_portfolio(client: APIClient) -> None:
    resp = client.get(PORTFOLIO_URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["buildings"] == []
    assert resp.data["totals"]["buildings"] == 0
    assert resp.data["totals"]["total_units"] == 0
    assert Decimal(resp.data["totals"]["total_rent"]) == Decimal("0.00")


# ── scoping ──────────────────────────────────────────────────────────────────


def test_portfolio_scoped_to_owner(client: APIClient, landlord: User) -> None:
    mine = BuildingFactory(owner=landlord)
    UnitFactory(building=mine, status=UnitStatus.OCCUPIED, rent=Decimal("11000.00"))
    # Another landlord's building + units must never appear.
    theirs = BuildingFactory()
    UnitFactory.create_batch(5, building=theirs, status=UnitStatus.OCCUPIED)

    resp = client.get(PORTFOLIO_URL)

    ids = [row["id"] for row in resp.data["buildings"]]
    assert ids == [str(mine.pk)]
    assert resp.data["totals"]["buildings"] == 1
    assert resp.data["totals"]["total_units"] == 1
    assert Decimal(resp.data["totals"]["total_rent"]) == Decimal("11000.00")


# ── performance (no N+1) ───────────────────────────────────────────────────────


def test_no_n_plus_one(client: APIClient, landlord: User) -> None:
    for _ in range(3):
        b = BuildingFactory(owner=landlord)
        UnitFactory.create_batch(2, building=b, status=UnitStatus.OCCUPIED)

    with CaptureQueriesContext(connection) as ctx:
        resp = client.get(PORTFOLIO_URL)

    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.data["buildings"]) == 3
    # The aggregation is a single annotated query; the building count must not
    # scale with the number of buildings (no per-building round-trips). Allow a
    # small constant budget for auth/session reads alongside the one data query.
    aggregation_queries = [
        q for q in ctx.captured_queries if "properties_building" in q["sql"]
    ]
    assert len(aggregation_queries) == 1


# ── auth / role gate ───────────────────────────────────────────────────────────


def test_requires_auth() -> None:
    resp = APIClient().get(PORTFOLIO_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_tenant_forbidden() -> None:
    tenant: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant)

    resp = api.get(PORTFOLIO_URL)

    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.data["error"]["code"] == "permission_denied"
