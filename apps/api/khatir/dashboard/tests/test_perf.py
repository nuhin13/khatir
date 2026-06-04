"""Dashboard query-count / N+1 regression test (EPIC-09 · T-010).

The dashboard selectors (:func:`khatir.dashboard.selectors.get_dashboard`)
aggregate every metric in the database in a fixed handful of queries, so the
query count must stay *constant* regardless of portfolio size — never scaling
with the number of buildings, units, leases, schedules, or expenses.

This test seeds a realistically-sized portfolio (5 buildings, 20 units, 50
rent-schedule payments, 20 expenses) and asserts the dashboard runs within a
bounded number of queries. If anyone introduces a per-row query (e.g. a loop
that touches the DB), the count jumps by tens and the assertion fails — catching
the regression in CI.

The bound is deliberately loose enough to absorb the selectors' legitimate
aggregate / grouped passes, yet far below what any N+1 over the seeded
collections would produce.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

from django.db import connection
from django.test import TestCase
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

# A constant, bounded number of aggregate queries. The selectors issue a fixed
# set of aggregate / grouped passes; this ceiling tolerates those joins while
# staying far below what any per-row N+1 over the 50 schedules / 20 expenses /
# 20 units would produce.
QUERY_BUDGET = 12

# Realistic portfolio size (spec §2 / §11).
N_BUILDINGS = 5
N_UNITS = 20
N_PAYMENTS = 50
N_EXPENSES = 20

# A spread of categories so the top-categories grouping has real work to do.
_CATEGORIES = [
    ExpenseCategory.PLUMBING,
    ExpenseCategory.ELECTRICAL,
    ExpenseCategory.PAINT,
    ExpenseCategory.UTILITY,
    ExpenseCategory.OTHER,
]

# A spread of statuses so collected / pending / overdue / late-payer all populate.
_STATUSES = [
    RentScheduleStatus.PAID,
    RentScheduleStatus.PENDING,
    RentScheduleStatus.REQUESTED,
    RentScheduleStatus.OVERDUE,
]


class DashboardQueryCountTest(TestCase):
    """N+1 guard for :func:`get_dashboard` against a realistic fixture."""

    @classmethod
    def setUpTestData(cls) -> None:
        cls.landlord = UserFactory(role=Role.LANDLORD)

        # 5 buildings, 20 units spread across them (4 units / building).
        buildings = [BuildingFactory(owner=cls.landlord) for _ in range(N_BUILDINGS)]
        units = []
        for i in range(N_UNITS):
            status = UnitStatus.OCCUPIED if i % 2 == 0 else UnitStatus.VACANT
            units.append(
                UnitFactory(building=buildings[i % N_BUILDINGS], status=status)
            )

        # One active lease per unit.
        leases = [
            LeaseFactory(landlord=cls.landlord, unit=unit, status=LeaseStatus.ACTIVE)
            for unit in units
        ]

        # 50 rent-schedule payments spread over leases, periods and statuses.
        for i in range(N_PAYMENTS):
            lease = leases[i % len(leases)]
            month = (i % 12) + 1
            RentScheduleFactory(
                lease=lease,
                period=f"2026-{month:02d}",
                due_date=datetime.date(2026, month, 5),
                amount=Decimal("10000.00"),
                status=_STATUSES[i % len(_STATUSES)],
            )

        # 20 expenses spread over units and categories.
        for i in range(N_EXPENSES):
            month = (i % 12) + 1
            ExpenseFactory(
                unit=units[i % len(units)],
                category=_CATEGORIES[i % len(_CATEGORIES)],
                amount=Decimal("1500.00"),
                date=datetime.date(2026, month, 10),
            )

    def test_dashboard_query_count(self) -> None:
        """The dashboard must run within the fixed query budget (no N+1).

        Upper-bound assertion: legitimate query-plan changes within budget stay
        green, while any per-row loop blows the ceiling and fails CI.
        """
        with CaptureQueriesContext(connection) as ctx:
            get_dashboard(self.landlord, months=6)

        count = len(ctx.captured_queries)
        self.assertLessEqual(
            count,
            QUERY_BUDGET,
            msg=(
                f"Dashboard issued {count} queries (budget {QUERY_BUDGET}); "
                "an N+1 may have been introduced."
            ),
        )
