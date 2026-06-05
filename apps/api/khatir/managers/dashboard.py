"""Manager consolidated-dashboard selector (EPIC-22 · T-004 §2).

Aggregates the EPIC-09 dashboard metrics across **all** owners a manager is
actively linked to. The single source of truth for which owners count is
:meth:`ManagerOwnerLink.objects.active_owner_ids_for` (T-001) — only ``active``
links (owner consent given, not revoked) contribute, so a pending or revoked
link never leaks an owner's numbers into the manager's view.

For each active-linked owner we reuse :func:`khatir.dashboard.selectors.get_dashboard`
**unchanged** — it scopes every queryset through the owner's ``for_user`` manager
(the owner is a landlord), so per-owner figures are computed exactly as that
owner would see them on their own dashboard. The manager payload then carries:

- ``owners`` — one :class:`OwnerDashboard` per active-linked owner; and
- ``total`` — a summed :class:`~khatir.dashboard.selectors.DashboardMetrics`
  (money summed, units summed, rates recomputed from the summed parts, and the
  monthly series summed period-by-period).

This is a pure read; nothing here writes, so there is no audit (audit is for
writes only, ``04_coding_conventions.md`` §3).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal

from khatir.accounts.models import User
from khatir.dashboard.selectors import (
    ZERO,
    CategoryTotal,
    DashboardMetrics,
    MonthPoint,
    get_dashboard,
)

from .models import ManagerOwnerLink


def _rate(part: Decimal, whole: Decimal) -> float:
    """``part / whole × 100`` rounded to 1 dp; ``0.0`` for an empty whole."""
    if whole <= ZERO:
        return 0.0
    return round(float(part / whole) * 100, 1)


@dataclass(frozen=True)
class OwnerDashboard:
    """One active-linked owner's dashboard, tagged with owner identity."""

    owner_id: int
    owner_name: str
    metrics: DashboardMetrics


@dataclass(frozen=True)
class ManagerDashboard:
    """The manager's consolidated payload: per-owner rows + a summed total."""

    owner_count: int = 0
    owners: list[OwnerDashboard] = field(default_factory=list)
    total: DashboardMetrics = field(default_factory=DashboardMetrics)


def _sum_series(per_owner: list[DashboardMetrics]) -> list[MonthPoint]:
    """Sum the monthly series period-by-period across owners.

    Every owner's series spans the same ``months`` window in the same order, so
    the points align by index; we sum ``collected``/``expense`` per slot.
    """
    if not per_owner:
        return []
    template = per_owner[0].monthly_series
    summed: list[MonthPoint] = []
    for idx, point in enumerate(template):
        collected = sum(
            (m.monthly_series[idx].collected for m in per_owner), ZERO
        )
        expense = sum(
            (m.monthly_series[idx].expense for m in per_owner), ZERO
        )
        summed.append(
            MonthPoint(period=point.period, collected=collected, expense=expense)
        )
    return summed


def _sum_top_categories(
    per_owner: list[DashboardMetrics], *, limit: int = 5
) -> list[CategoryTotal]:
    """Combine per-owner top-category totals into a single top-``limit`` list."""
    totals: dict[str, Decimal] = {}
    for metrics in per_owner:
        for cat in metrics.top_expense_categories:
            totals[cat.category] = totals.get(cat.category, ZERO) + cat.amount
    ordered = sorted(totals.items(), key=lambda kv: kv[1], reverse=True)
    return [CategoryTotal(category=c, amount=a) for c, a in ordered[:limit]]


def _sum_metrics(per_owner: list[DashboardMetrics]) -> DashboardMetrics:
    """Sum per-owner metrics into one portfolio-wide total.

    Money and counts are added; rates are **recomputed** from the summed parts
    (never averaged) so the total collection/occupancy rate is correct for the
    whole portfolio.
    """
    if not per_owner:
        return DashboardMetrics()

    total_collected = sum((m.total_collected for m in per_owner), ZERO)
    total_pending = sum((m.total_pending for m in per_owner), ZERO)
    total_overdue = sum((m.total_overdue for m in per_owner), ZERO)
    total_expense = sum((m.total_expense for m in per_owner), ZERO)
    occupied_units = sum(m.occupied_units for m in per_owner)
    total_units = sum(m.total_units for m in per_owner)
    late_payer_count = sum(m.late_payer_count for m in per_owner)

    denominator = total_collected + total_pending + total_overdue

    return DashboardMetrics(
        total_collected=total_collected,
        total_pending=total_pending,
        total_overdue=total_overdue,
        collection_rate=_rate(total_collected, denominator),
        occupied_units=occupied_units,
        total_units=total_units,
        occupancy_rate=_rate(Decimal(occupied_units), Decimal(total_units)),
        total_income=total_collected,
        total_expense=total_expense,
        net=total_collected - total_expense,
        late_payer_count=late_payer_count,
        monthly_series=_sum_series(per_owner),
        top_expense_categories=_sum_top_categories(per_owner),
    )


def get_manager_dashboard(manager: User, months: int = 6) -> ManagerDashboard:
    """Aggregate dashboard metrics across a manager's active-linked owners.

    Only owners with an **active** :class:`ManagerOwnerLink` to ``manager`` are
    included (consent enforced). A manager with no active links resolves to an
    empty payload (no owners, all-zero total) — never another manager's data.
    """
    owner_ids = ManagerOwnerLink.objects.active_owner_ids_for(manager)
    if not owner_ids:
        return ManagerDashboard()

    # Stable order by id so the response is deterministic across calls.
    owners = list(User.objects.filter(pk__in=owner_ids).order_by("pk"))

    rows: list[OwnerDashboard] = []
    per_owner_metrics: list[DashboardMetrics] = []
    for owner in owners:
        metrics = get_dashboard(owner, months=months)
        per_owner_metrics.append(metrics)
        rows.append(
            OwnerDashboard(
                owner_id=owner.pk,
                owner_name=owner.name or owner.phone or "",
                metrics=metrics,
            )
        )

    return ManagerDashboard(
        owner_count=len(rows),
        owners=rows,
        total=_sum_metrics(per_owner_metrics),
    )
