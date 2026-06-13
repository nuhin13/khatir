"""Tests for the expense summary selectors + endpoint (T-012 §12).

Two layers:

* the pure selectors (``expense_total_by_category`` / ``expense_total_by_month``)
  — exercises the aggregation math, owner scoping, the optional filters, and the
  empty case directly;
* the ``GET /api/v1/expenses/summary`` endpoint — confirms the wired-up shape,
  auth/role gating, and cross-user isolation.

Summary numbers must match the raw expenses (T-012 §12, manual QA).
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
from khatir.maintenance.enums import ExpenseCategory
from khatir.maintenance.selectors import (
    expense_total_by_category,
    expense_total_by_month,
)
from khatir.maintenance.tests.factories import ExpenseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db

SUMMARY_URL = "/api/v1/expenses/summary"


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


def _cat_map(rows: list[dict[str, object]]) -> dict[object, object]:
    return {row["category"]: row["total"] for row in rows}


def _month_map(rows: list[dict[str, object]]) -> dict[object, object]:
    return {row["month"]: row["total"] for row in rows}


# ── selector: by category ─────────────────────────────────────────────────────


def test_summary_by_category(landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, category=ExpenseCategory.PLUMBING, amount=Decimal("100.00"))
    ExpenseFactory(unit=unit, category=ExpenseCategory.PLUMBING, amount=Decimal("250.50"))
    ExpenseFactory(unit=unit, category=ExpenseCategory.PAINT, amount=Decimal("400.00"))

    rows = expense_total_by_category(landlord)

    totals = _cat_map(rows)
    assert totals[ExpenseCategory.PLUMBING.value] == Decimal("350.50")
    assert totals[ExpenseCategory.PAINT.value] == Decimal("400.00")
    # Categories without expenses are simply absent.
    assert ExpenseCategory.ELECTRICAL.value not in totals


def test_summary_by_category_scoped_to_owner(landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, category=ExpenseCategory.PLUMBING, amount=Decimal("100.00"))
    # Another landlord's expense must never be counted.
    ExpenseFactory(category=ExpenseCategory.PLUMBING, amount=Decimal("999.00"))

    rows = expense_total_by_category(landlord)

    assert _cat_map(rows) == {ExpenseCategory.PLUMBING.value: Decimal("100.00")}


def test_summary_by_category_empty(landlord: User) -> None:
    assert expense_total_by_category(landlord) == []


# ── selector: by month ────────────────────────────────────────────────────────


def test_summary_by_month(landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 3, 5), amount=Decimal("100.00"))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 3, 28), amount=Decimal("50.00"))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 4, 1), amount=Decimal("200.00"))

    rows = expense_total_by_month(landlord)

    totals = _month_map(rows)
    assert totals[datetime.date(2026, 3, 1)] == Decimal("150.00")
    assert totals[datetime.date(2026, 4, 1)] == Decimal("200.00")
    # Chronological order for time-series plotting.
    months = [row["month"] for row in rows]
    assert months == sorted(months)


def test_summary_by_month_scoped_to_owner(landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 3, 5), amount=Decimal("100.00"))
    ExpenseFactory(date=datetime.date(2026, 3, 5), amount=Decimal("999.00"))

    rows = expense_total_by_month(landlord)

    assert _month_map(rows) == {datetime.date(2026, 3, 1): Decimal("100.00")}


def test_summary_filters_by_building(landlord: User) -> None:
    building_a = BuildingFactory(owner=landlord)
    building_b = BuildingFactory(owner=landlord)
    ExpenseFactory(unit=UnitFactory(building=building_a), amount=Decimal("100.00"))
    ExpenseFactory(unit=UnitFactory(building=building_b), amount=Decimal("999.00"))

    rows = expense_total_by_category(landlord, building=building_a.pk)

    assert sum(row["total"] for row in rows) == Decimal("100.00")


def test_summary_filters_by_date_range(landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 6, 15), amount=Decimal("100.00"))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 1, 1), amount=Decimal("999.00"))

    rows = expense_total_by_month(
        landlord,
        date_from=datetime.date(2026, 6, 1),
        date_to=datetime.date(2026, 6, 30),
    )

    assert _month_map(rows) == {datetime.date(2026, 6, 1): Decimal("100.00")}


# ── endpoint ───────────────────────────────────────────────────────────────────


def test_summary_endpoint(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(
        unit=unit,
        category=ExpenseCategory.PLUMBING,
        amount=Decimal("100.00"),
        date=datetime.date(2026, 3, 5),
    )
    ExpenseFactory(
        unit=unit,
        category=ExpenseCategory.PAINT,
        amount=Decimal("250.00"),
        date=datetime.date(2026, 4, 10),
    )

    resp = client.get(SUMMARY_URL)

    assert resp.status_code == status.HTTP_200_OK
    by_category = {row["category"]: row["total"] for row in resp.data["by_category"]}
    assert by_category[ExpenseCategory.PLUMBING.value] == "100.00"
    assert by_category[ExpenseCategory.PAINT.value] == "250.00"
    by_month = {row["month"]: row["total"] for row in resp.data["by_month"]}
    assert by_month["2026-03-01"] == "100.00"
    assert by_month["2026-04-01"] == "250.00"


def test_summary_endpoint_scoped(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, amount=Decimal("100.00"))
    ExpenseFactory(amount=Decimal("999.00"))  # foreign landlord

    resp = client.get(SUMMARY_URL)

    total = sum(Decimal(row["total"]) for row in resp.data["by_category"])
    assert total == Decimal("100.00")


def test_summary_endpoint_requires_auth() -> None:
    resp = APIClient().get(SUMMARY_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_summary_endpoint_tenant_forbidden() -> None:
    tenant_user: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    resp = api.get(SUMMARY_URL)

    assert resp.status_code == status.HTTP_403_FORBIDDEN
