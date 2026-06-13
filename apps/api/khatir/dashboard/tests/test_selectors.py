"""Tests for the dashboard aggregation selectors (EPIC-09 · T-001).

Each metric is exercised against hand-built fixture data so the asserted numbers
match the raw records. Scoping is verified by seeding a *second* landlord whose
data must never leak into the first landlord's dashboard. A query-count assertion
guards against N+1 regressions.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from django.db import connection
from django.test.utils import CaptureQueriesContext

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.dashboard.selectors import get_dashboard
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.maintenance.enums import ExpenseCategory
from khatir.maintenance.tests.factories import ExpenseFactory
from khatir.properties.enums import UnitStatus
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord():
    return UserFactory(role=Role.LANDLORD)


def _unit(owner, *, status=UnitStatus.OCCUPIED):
    building = BuildingFactory(owner=owner)
    return UnitFactory(building=building, status=status)


def _lease(owner, unit):
    return LeaseFactory(landlord=owner, unit=unit, status=LeaseStatus.ACTIVE)


def test_collection_metrics_and_rate(landlord):
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease, period="2026-01", amount=Decimal("10000.00"),
        status=RentScheduleStatus.PAID,
    )
    RentScheduleFactory(
        lease=lease, period="2026-02", amount=Decimal("5000.00"),
        status=RentScheduleStatus.PENDING,
    )
    RentScheduleFactory(
        lease=lease, period="2026-03", amount=Decimal("5000.00"),
        status=RentScheduleStatus.OVERDUE,
    )

    dash = get_dashboard(landlord)

    assert dash.total_collected == Decimal("10000.00")
    assert dash.total_pending == Decimal("5000.00")
    assert dash.total_overdue == Decimal("5000.00")
    # 10000 / 20000 * 100 = 50.0
    assert dash.collection_rate == 50.0


def test_collection_rate_empty_denominator_is_zero(landlord):
    dash = get_dashboard(landlord)
    assert dash.collection_rate == 0.0
    assert dash.total_collected == Decimal("0.00")


def test_requested_counts_as_pending(landlord):
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease, period="2026-04", amount=Decimal("7000.00"),
        status=RentScheduleStatus.REQUESTED,
    )
    dash = get_dashboard(landlord)
    assert dash.total_pending == Decimal("7000.00")


def test_occupancy(landlord):
    _unit(landlord, status=UnitStatus.OCCUPIED)
    _unit(landlord, status=UnitStatus.OCCUPIED)
    _unit(landlord, status=UnitStatus.VACANT)
    _unit(landlord, status=UnitStatus.MAINTENANCE)

    dash = get_dashboard(landlord)
    assert dash.occupied_units == 2
    assert dash.total_units == 4
    assert dash.occupancy_rate == 50.0


def test_occupancy_empty_is_zero(landlord):
    dash = get_dashboard(landlord)
    assert dash.total_units == 0
    assert dash.occupancy_rate == 0.0


def test_monthly_series_shape_and_zero_fill(landlord):
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    # Seed a period far in the past so it falls OUTSIDE the requested window:
    # every returned month must therefore zero-fill.
    RentScheduleFactory(
        lease=lease, period="2000-01", amount=Decimal("12000.00"),
        status=RentScheduleStatus.PAID,
    )
    ExpenseFactory(
        unit=unit, amount=Decimal("3000.00"),
        date=datetime.date(2000, 1, 10),
    )

    dash = get_dashboard(landlord, months=4)

    assert len(dash.monthly_series) == 4
    # Oldest → newest ordering.
    periods = [p.period for p in dash.monthly_series]
    assert periods == sorted(periods)
    # All out-of-window months zero-fill (the seed sits in year 2000).
    assert all(p.collected == Decimal("0.00") for p in dash.monthly_series)
    assert all(p.expense == Decimal("0.00") for p in dash.monthly_series)


def test_monthly_series_includes_in_window_data(landlord):
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    today = datetime.date.today()
    this_period = f"{today.year:04d}-{today.month:02d}"
    RentScheduleFactory(
        lease=lease, period=this_period, amount=Decimal("9000.00"),
        status=RentScheduleStatus.PAID,
    )
    ExpenseFactory(unit=unit, amount=Decimal("1500.00"), date=today)

    dash = get_dashboard(landlord, months=3)
    current = {p.period: p for p in dash.monthly_series}[this_period]
    assert current.collected == Decimal("9000.00")
    assert current.expense == Decimal("1500.00")


def test_months_floor_is_one(landlord):
    dash = get_dashboard(landlord, months=0)
    assert len(dash.monthly_series) == 1


def test_income_vs_expense_and_net(landlord):
    unit = _unit(landlord)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease, period="2026-01", amount=Decimal("20000.00"),
        status=RentScheduleStatus.PAID,
    )
    ExpenseFactory(unit=unit, amount=Decimal("5000.00"), date=datetime.date(2026, 1, 9))
    ExpenseFactory(unit=unit, amount=Decimal("2000.00"), date=datetime.date(2026, 1, 9))

    dash = get_dashboard(landlord)
    assert dash.total_income == Decimal("20000.00")
    assert dash.total_expense == Decimal("7000.00")
    assert dash.net == Decimal("13000.00")


def test_top_expense_categories(landlord):
    unit = _unit(landlord)
    jan = datetime.date(2026, 1, 1)
    feb = datetime.date(2026, 2, 1)
    ExpenseFactory(
        unit=unit, category=ExpenseCategory.PLUMBING,
        amount=Decimal("9000.00"), date=jan,
    )
    ExpenseFactory(
        unit=unit, category=ExpenseCategory.PLUMBING,
        amount=Decimal("1000.00"), date=feb,
    )
    ExpenseFactory(
        unit=unit, category=ExpenseCategory.PAINT,
        amount=Decimal("4000.00"), date=jan,
    )
    ExpenseFactory(
        unit=unit, category=ExpenseCategory.ELECTRICAL,
        amount=Decimal("2000.00"), date=jan,
    )

    dash = get_dashboard(landlord)
    cats = dash.top_expense_categories
    assert cats[0].category == ExpenseCategory.PLUMBING
    assert cats[0].amount == Decimal("10000.00")
    assert cats[1].category == ExpenseCategory.PAINT
    assert cats[1].amount == Decimal("4000.00")
    # All distinct categories present, capped at 5.
    assert len(cats) == 3


def test_late_payer_count_distinct_leases(landlord):
    unit_a = _unit(landlord)
    lease_a = _lease(landlord, unit_a)
    unit_b = _unit(landlord)
    lease_b = _lease(landlord, unit_b)
    overdue = RentScheduleStatus.OVERDUE
    # Two overdue schedules on the SAME lease → counts as one late payer.
    RentScheduleFactory(lease=lease_a, period="2026-01", status=overdue)
    RentScheduleFactory(lease=lease_a, period="2026-02", status=overdue)
    RentScheduleFactory(lease=lease_b, period="2026-01", status=overdue)
    # A paid one does not count.
    RentScheduleFactory(
        lease=lease_b, period="2026-02", status=RentScheduleStatus.PAID
    )

    dash = get_dashboard(landlord)
    assert dash.late_payer_count == 2


def test_scoped_to_owner(landlord):
    other = UserFactory(role=Role.LANDLORD)
    # Other landlord's data.
    other_unit = _unit(other, status=UnitStatus.OCCUPIED)
    other_lease = _lease(other, other_unit)
    RentScheduleFactory(
        lease=other_lease, period="2026-01",
        amount=Decimal("99999.00"), status=RentScheduleStatus.PAID,
    )
    ExpenseFactory(
        unit=other_unit, amount=Decimal("88888.00"),
        date=datetime.date(2026, 1, 1),
    )

    # Our landlord has nothing.
    dash = get_dashboard(landlord)
    assert dash.total_collected == Decimal("0.00")
    assert dash.total_expense == Decimal("0.00")
    assert dash.total_units == 0
    assert dash.late_payer_count == 0


def test_unauthenticated_user_gets_empty(db):
    from django.contrib.auth.models import AnonymousUser

    dash = get_dashboard(AnonymousUser())
    assert dash.total_collected == Decimal("0.00")
    assert dash.total_units == 0


def test_no_n_plus_one_query_count(landlord):
    # Seed several leases / schedules / expenses / units.
    for i in range(5):
        status = UnitStatus.OCCUPIED if i % 2 else UnitStatus.VACANT
        unit = _unit(landlord, status=status)
        lease = _lease(landlord, unit)
        RentScheduleFactory(
            lease=lease, period=f"2026-0{i + 1}",
            amount=Decimal("1000.00"), status=RentScheduleStatus.PAID,
        )
        RentScheduleFactory(
            lease=lease, period=f"2025-0{i + 1}",
            amount=Decimal("500.00"), status=RentScheduleStatus.OVERDUE,
        )
        ExpenseFactory(
            unit=unit, amount=Decimal("100.00"),
            date=datetime.date(2026, i + 1, 1),
        )

    with CaptureQueriesContext(connection) as ctx:
        get_dashboard(landlord, months=6)

    # Fixed, bounded number of aggregate queries — must not scale with rows.
    assert len(ctx.captured_queries) <= 12
