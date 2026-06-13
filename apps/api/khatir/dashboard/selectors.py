"""Read-side dashboard selectors (EPIC-09 · T-001).

Pure read functions that compute the landlord dashboard's metrics from existing
domain data. They never write. Every queryset is scoped to the requesting user
through the owning domain's ``for_user`` manager (or a ``for_user`` subquery for
the child ``RentSchedule`` rows), so a landlord only ever sees their own
numbers — a missing scope is a P0 security bug (``04_coding_conventions.md`` §3).

Money lives in :class:`~khatir.leases.models.RentSchedule` (the source of truth
for what is collected / pending / overdue per month) and
:class:`~khatir.maintenance.models.Expense`. Aggregations are done in the
database (``annotate``/``aggregate``/``values``) in a handful of fixed queries —
never per-row — so the dashboard stays O(1) queries regardless of portfolio size
(no N+1).

Conventions
-----------
- ``collection_rate = collected / (collected + pending + overdue) × 100`` with an
  empty denominator yielding ``0.0`` (``§15``).
- ``monthly_series`` returns the last ``months`` calendar months (oldest →
  newest), filling ``0`` for months with no rent collected and/or no expense.
- All amounts are :class:`~decimal.Decimal` Taka; ``occupancy`` /
  ``late_payer_count`` are ints; rates are floats rounded to one decimal place.
"""

from __future__ import annotations

import datetime
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from django.db.models import Count, DecimalField, Q, QuerySet, Sum, Value
from django.db.models.functions import Coalesce, TruncMonth
from django.utils import timezone

from khatir.leases.enums import RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.maintenance.models import Expense
from khatir.properties.enums import UnitStatus
from khatir.properties.models import Unit

ZERO = Decimal("0.00")

#: Statuses that count as still-owed-but-not-late (vs. ``OVERDUE``).
_PENDING_STATUSES = (RentScheduleStatus.PENDING, RentScheduleStatus.REQUESTED)

_MONEY = DecimalField(max_digits=12, decimal_places=2)


def _money_sum(field_name: str, *, filter: Q | None = None) -> Coalesce:
    """A ``Sum`` over a money field that returns ``0.00`` instead of ``NULL``."""
    return Coalesce(
        Sum(field_name, filter=filter),
        Value(ZERO),
        output_field=_MONEY,
    )


@dataclass(frozen=True)
class MonthPoint:
    """One month of the dashboard time series."""

    period: str  # canonical ``YYYY-MM``
    collected: Decimal
    expense: Decimal


@dataclass(frozen=True)
class CategoryTotal:
    """One expense-category total, for the top-categories breakdown."""

    category: str
    amount: Decimal


@dataclass(frozen=True)
class DashboardMetrics:
    """The full, typed dashboard payload returned by :func:`get_dashboard`."""

    total_collected: Decimal = ZERO
    total_pending: Decimal = ZERO
    total_overdue: Decimal = ZERO
    collection_rate: float = 0.0
    occupied_units: int = 0
    total_units: int = 0
    occupancy_rate: float = 0.0
    total_income: Decimal = ZERO
    total_expense: Decimal = ZERO
    net: Decimal = ZERO
    late_payer_count: int = 0
    monthly_series: list[MonthPoint] = field(default_factory=list)
    top_expense_categories: list[CategoryTotal] = field(default_factory=list)


def _scoped_schedules(user: Any) -> QuerySet[RentSchedule]:
    """RentSchedule rows on leases the *user* may see (``for_user`` subquery)."""
    visible_leases = Lease.objects.for_user(user).values("pk")
    return RentSchedule.objects.filter(lease__in=visible_leases)


def _rate(part: Decimal, whole: Decimal) -> float:
    """``part / whole × 100`` rounded to 1 dp; ``0.0`` for an empty whole."""
    if whole <= ZERO:
        return 0.0
    return round(float(part / whole) * 100, 1)


def _last_n_periods(months: int, *, today: datetime.date) -> list[str]:
    """The last *months* ``YYYY-MM`` keys, oldest → newest, ending this month."""
    periods: list[str] = []
    year, month = today.year, today.month
    for _ in range(months):
        periods.append(f"{year:04d}-{month:02d}")
        month -= 1
        if month == 0:
            month = 12
            year -= 1
    return list(reversed(periods))


def _collection_metrics(schedules: QuerySet[RentSchedule]) -> dict[str, Decimal]:
    """Single aggregate pass for collected / pending / overdue money."""
    agg = schedules.aggregate(
        collected=_money_sum(
            "amount", filter=Q(status=RentScheduleStatus.PAID)
        ),
        pending=_money_sum(
            "amount", filter=Q(status__in=_PENDING_STATUSES)
        ),
        overdue=_money_sum(
            "amount", filter=Q(status=RentScheduleStatus.OVERDUE)
        ),
    )
    return {
        "collected": agg["collected"],
        "pending": agg["pending"],
        "overdue": agg["overdue"],
    }


def _occupancy(user: Any) -> tuple[int, int]:
    """``(occupied_units, total_units)`` over the units the *user* may see.

    A single grouped ``Count`` pass: total units and the occupied subset.
    """
    agg = Unit.objects.for_user(user).aggregate(
        total=Count("pk"),
        occupied=Count("pk", filter=Q(status=UnitStatus.OCCUPIED)),
    )
    return agg["occupied"], agg["total"]


def _collected_by_period(schedules: QuerySet[RentSchedule]) -> dict[str, Decimal]:
    """Map ``YYYY-MM`` → collected (paid) amount, one grouped query."""
    rows = (
        schedules.filter(status=RentScheduleStatus.PAID)
        .values("period")
        .annotate(total=_money_sum("amount"))
    )
    return {row["period"]: row["total"] for row in rows}


def _expense_by_period(expenses: QuerySet[Expense]) -> dict[str, Decimal]:
    """Map ``YYYY-MM`` → total expense, one grouped query (TruncMonth on date)."""
    rows = (
        expenses.annotate(month=TruncMonth("date"))
        .values("month")
        .annotate(total=_money_sum("amount"))
    )
    out: dict[str, Decimal] = {}
    for row in rows:
        month: datetime.date | None = row["month"]
        if month is None:
            continue
        out[f"{month.year:04d}-{month.month:02d}"] = row["total"]
    return out


def _top_expense_categories(
    expenses: QuerySet[Expense], *, limit: int = 5
) -> list[CategoryTotal]:
    """Top *limit* expense categories by total amount (descending)."""
    rows = (
        expenses.values("category")
        .annotate(total=_money_sum("amount"))
        .order_by("-total")[:limit]
    )
    return [
        CategoryTotal(category=row["category"], amount=row["total"]) for row in rows
    ]


def _late_payer_count(schedules: QuerySet[RentSchedule]) -> int:
    """Distinct leases with at least one overdue schedule (one query)."""
    return (
        schedules.filter(status=RentScheduleStatus.OVERDUE)
        .values("lease")
        .distinct()
        .count()
    )


def get_dashboard(user: Any, months: int = 6) -> DashboardMetrics:
    """Compute every dashboard metric for *user* over the last *months* months.

    Pure read, fully scoped through ``for_user``. Returns a typed
    :class:`DashboardMetrics`. An unauthenticated / non-owner user resolves to an
    empty (all-zero) payload because every underlying ``for_user`` queryset is
    empty — never another landlord's data.
    """
    if months < 1:
        months = 1

    schedules = _scoped_schedules(user)
    expenses = Expense.objects.for_user(user)

    collection = _collection_metrics(schedules)
    collected = collection["collected"]
    pending = collection["pending"]
    overdue = collection["overdue"]
    denominator = collected + pending + overdue

    occupied_units, total_units = _occupancy(user)

    total_expense = expenses.aggregate(total=_money_sum("amount"))["total"]

    collected_by_period = _collected_by_period(schedules)
    expense_by_period = _expense_by_period(expenses)
    periods = _last_n_periods(months, today=timezone.localdate())
    series = [
        MonthPoint(
            period=period,
            collected=collected_by_period.get(period, ZERO),
            expense=expense_by_period.get(period, ZERO),
        )
        for period in periods
    ]

    return DashboardMetrics(
        total_collected=collected,
        total_pending=pending,
        total_overdue=overdue,
        collection_rate=_rate(collected, denominator),
        occupied_units=occupied_units,
        total_units=total_units,
        occupancy_rate=_rate(Decimal(occupied_units), Decimal(total_units)),
        total_income=collected,
        total_expense=total_expense,
        net=collected - total_expense,
        late_payer_count=_late_payer_count(schedules),
        monthly_series=series,
        top_expense_categories=_top_expense_categories(expenses),
    )
