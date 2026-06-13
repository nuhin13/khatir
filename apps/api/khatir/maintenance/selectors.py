"""Read-only expense aggregation selectors (T-012).

A *selector* is a pure, read-only query function (``04_coding_conventions.md``):
no writes, no audit, no side effects. These power the EPIC-09 dashboard charts
(expense totals by category and by month) and are reused by the optional
``GET /api/v1/expenses/summary`` endpoint.

Every selector starts from ``Expense.objects.for_user(user)`` so the result is
**always** row-scoped to the units the caller can see (a missing scope is a P0
bug, ``04_coding_conventions.md`` §3). Aggregation is pushed into the database
via the ORM — a single grouped query per breakdown, never a Python loop over
rows (no N+1). Money sums are ``Decimal`` and default to ``0.00`` when a group
has no rows.

The same optional ``building`` / ``unit`` / ``date_from`` / ``date_to`` filters
the list endpoint accepts can be passed through, so a dashboard can scope a
summary to one building or a date window.
"""

from __future__ import annotations

import datetime
from decimal import Decimal
from typing import Any, TypedDict

from django.db.models import Sum
from django.db.models.functions import TruncMonth

from .models import Expense

_CENTS = Decimal("0.01")


def _money(value: Decimal | None) -> Decimal:
    """Normalise a grouped ``Sum`` to a 2-decimal Taka amount (``0.00`` if empty)."""
    return (value or Decimal("0.00")).quantize(_CENTS)


class CategoryTotal(TypedDict):
    """One row of the by-category breakdown."""

    category: str
    total: Decimal


class MonthTotal(TypedDict):
    """One row of the by-month breakdown (``month`` is the first of the month)."""

    month: datetime.date
    total: Decimal


def _scoped_queryset(
    user: Any,
    *,
    building: Any = None,
    unit: Any = None,
    date_from: datetime.date | None = None,
    date_to: datetime.date | None = None,
) -> Any:
    """The user-scoped expense queryset narrowed by the optional filters.

    Scoping comes first (``for_user``) so the filters can only ever *narrow* the
    already-isolated set, never widen it across owners.
    """
    qs = Expense.objects.for_user(user)
    if unit:
        qs = qs.filter(unit_id=unit)
    if building:
        qs = qs.filter(unit__building_id=building)
    if date_from is not None:
        qs = qs.filter(date__gte=date_from)
    if date_to is not None:
        qs = qs.filter(date__lte=date_to)
    return qs


def expense_total_by_category(
    user: Any,
    *,
    building: Any = None,
    unit: Any = None,
    date_from: datetime.date | None = None,
    date_to: datetime.date | None = None,
) -> list[CategoryTotal]:
    """Sum of expense ``amount`` grouped by category, scoped to ``user``.

    One grouped DB query; ordered by category for a stable, deterministic
    result. Categories with no expenses are simply absent (not zero rows).
    """
    rows = (
        _scoped_queryset(
            user,
            building=building,
            unit=unit,
            date_from=date_from,
            date_to=date_to,
        )
        .values("category")
        .annotate(total=Sum("amount"))
        .order_by("category")
    )
    return [
        CategoryTotal(category=row["category"], total=_money(row["total"]))
        for row in rows
    ]


def expense_total_by_month(
    user: Any,
    *,
    building: Any = None,
    unit: Any = None,
    date_from: datetime.date | None = None,
    date_to: datetime.date | None = None,
) -> list[MonthTotal]:
    """Sum of expense ``amount`` grouped by calendar month, scoped to ``user``.

    Buckets by the truncated month of the expense ``date`` (each ``month`` is the
    first day of that month), one grouped DB query, ordered chronologically so
    the dashboard can plot a time series directly.
    """
    rows = (
        _scoped_queryset(
            user,
            building=building,
            unit=unit,
            date_from=date_from,
            date_to=date_to,
        )
        .annotate(month=TruncMonth("date"))
        .values("month")
        .annotate(total=Sum("amount"))
        .order_by("month")
    )
    return [
        MonthTotal(month=row["month"], total=_money(row["total"])) for row in rows
    ]
