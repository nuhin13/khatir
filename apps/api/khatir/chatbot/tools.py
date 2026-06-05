"""Scoped, read-only data tools for the chatbot (EPIC-23.T-003 §1-2).

A small set of lookups the assistant can use to answer the user's data questions
("what's my collection this month?", "how many units are occupied?", "how many
tenants are overdue?"). Every function here is:

* **Read-only.** Nothing writes; these are pure projections of existing data.
* **Strictly own-data.** The only subject is the *authenticated* ``user`` passed
  in. No function accepts a user id (or any other ownership selector), so there
  is no parameter through which the caller could ask about *someone else's*
  portfolio — the epic's headline risk ("bot leaks another user's data"). The
  underlying numbers come from EPIC-09's :func:`khatir.dashboard.selectors.get_dashboard`,
  which scopes every queryset through the owning domain's ``for_user`` manager,
  so an anonymous / non-owner user resolves to an all-zero summary rather than
  another landlord's records.

The tools reuse the dashboard selector instead of re-querying so the chatbot can
never drift from the numbers the user already sees on their dashboard, and so the
P0 scoping guarantee lives in exactly one place.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import TYPE_CHECKING

from khatir.dashboard.selectors import get_dashboard

if TYPE_CHECKING:
    from khatir.accounts.models import User


@dataclass(frozen=True)
class PortfolioSummary:
    """The own-data snapshot the assistant may reference about ``user``.

    A flat, typed projection of the fields of EPIC-09's dashboard the bot needs
    to answer the common data questions. All amounts are Taka
    (:class:`~decimal.Decimal`); counts and rates are plain numbers. Every value
    belongs to ``user`` and only to ``user``.
    """

    #: Rent collected this calendar month-to-date window (Taka).
    collected: Decimal
    #: Still-owed-but-not-late rent (Taka).
    pending: Decimal
    #: Overdue rent (Taka).
    overdue: Decimal
    #: ``collected / (collected + pending + overdue) × 100``, 1 dp.
    collection_rate: float
    #: Occupied units / total units in the user's portfolio.
    occupied_units: int
    total_units: int
    #: ``occupied / total × 100``, 1 dp.
    occupancy_rate: float
    #: Distinct leases with at least one overdue schedule.
    overdue_count: int

    @property
    def is_empty(self) -> bool:
        """True when the user has no portfolio data worth summarising."""
        return self.total_units == 0 and (
            self.collected + self.pending + self.overdue
        ) == Decimal("0.00")


def get_portfolio_summary(user: User) -> PortfolioSummary:
    """Return ``user``'s own portfolio/rent summary (read-only, own-data only).

    There is intentionally **no** user-id parameter: the subject is always the
    authenticated caller. Delegates the scoped aggregation to the EPIC-09
    dashboard selector so the chatbot reports exactly the numbers the user sees
    on their dashboard, and inherits its ``for_user`` scoping.
    """
    metrics = get_dashboard(user)
    return PortfolioSummary(
        collected=metrics.total_collected,
        pending=metrics.total_pending,
        overdue=metrics.total_overdue,
        collection_rate=metrics.collection_rate,
        occupied_units=metrics.occupied_units,
        total_units=metrics.total_units,
        occupancy_rate=metrics.occupancy_rate,
        overdue_count=metrics.late_payer_count,
    )


def format_portfolio_summary(summary: PortfolioSummary) -> str:
    """Render ``summary`` as a compact, human-readable block for the prompt.

    Returns an empty string when there is nothing to report, so an empty
    portfolio adds no noise (and no misleading all-zero figures) to the system
    prompt. Amounts are formatted as plain Taka integers/decimals; the model
    receives only the user's own already-scoped numbers.
    """
    if summary.is_empty:
        return ""
    lines = [
        f"Rent collected (this period): BDT {summary.collected}",
        f"Rent pending: BDT {summary.pending}",
        f"Rent overdue: BDT {summary.overdue}",
        f"Collection rate: {summary.collection_rate}%",
        f"Occupied units: {summary.occupied_units} of {summary.total_units} "
        f"({summary.occupancy_rate}% occupancy)",
        f"Overdue tenants: {summary.overdue_count}",
    ]
    return "\n".join(lines)
