"""Per-owner manager report builder (EPIC-22 · T-005 §2).

Builds a one-page summary report — collection, occupancy, expenses — for a
single owner a manager is **actively** linked to, and renders it to PDF bytes.

Reuse, not reinvention (``§EPIC-05``):

- the metrics come from EPIC-09's :func:`khatir.dashboard.selectors.get_dashboard`
  **unchanged**, so the owner's collection/occupancy/expense figures are computed
  exactly as on their own dashboard (every queryset scoped through the owner's
  ``for_user`` manager); and
- the PDF is drawn with EPIC-05's deterministic, dependency-free
  :func:`khatir.dmpforms.pdf._render_pdf` placement primitive, so the same input
  always yields identical bytes (golden-testable, no timestamps/random ids).

Building the report is a pure read of the owner's data; the **access** to that
owner's personal/financial data by a manager is the auditable event, written by
the view (``04_coding_conventions.md`` §11).
"""

from __future__ import annotations

from dataclasses import dataclass

from khatir.accounts.models import User
from khatir.dashboard.selectors import DashboardMetrics, get_dashboard
from khatir.dmpforms.pdf import PAGE_WIDTH, _render_pdf

#: Report template version — bump on any layout/field change (mirrors EPIC-05).
REPORT_VERSION = "2026.1"

# Fixed baselines (PDF points, origin bottom-left) for the summary rows.
_TITLE_Y = 760
_SUBTITLE_Y = 736
_LEFT_X = 72
_FIRST_ROW_Y = 696
_ROW_STEP = 24
_SECTION_GAP = 12


@dataclass(frozen=True)
class OwnerReport:
    """A single owner's report payload, ready to render."""

    owner_id: int
    owner_name: str
    months: int
    metrics: DashboardMetrics


def build_owner_report(owner: User, *, months: int = 6) -> OwnerReport:
    """Assemble the per-owner report metrics (pure read, owner-scoped)."""
    metrics = get_dashboard(owner, months=months)
    return OwnerReport(
        owner_id=owner.pk,
        owner_name=owner.name or owner.phone or "",
        months=months,
        metrics=metrics,
    )


def _summary_rows(report: OwnerReport) -> list[str]:
    """Human-readable ``label: value`` rows for the three summary sections."""
    m = report.metrics
    return [
        "Collection",
        f"  Collected: {m.total_collected}",
        f"  Pending: {m.total_pending}",
        f"  Overdue: {m.total_overdue}",
        f"  Collection rate: {m.collection_rate}%",
        f"  Late payers: {m.late_payer_count}",
        "Occupancy",
        f"  Occupied units: {m.occupied_units}",
        f"  Total units: {m.total_units}",
        f"  Occupancy rate: {m.occupancy_rate}%",
        "Expenses",
        f"  Total expense: {m.total_expense}",
        f"  Net (income - expense): {m.net}",
    ]


def render_owner_report_pdf(report: OwnerReport) -> bytes:
    """Render ``report`` to deterministic PDF bytes (reuses EPIC-05 primitive)."""
    placements: list[tuple[int, int, str]] = [
        (
            PAGE_WIDTH // 2 - 140,
            _TITLE_Y,
            f"Owner Summary Report ({REPORT_VERSION})",
        ),
        (
            _LEFT_X,
            _SUBTITLE_Y,
            f"Owner: {report.owner_name}  ·  Window: last {report.months} months",
        ),
    ]

    y = _FIRST_ROW_Y
    for row in _summary_rows(report):
        # Section headers (no leading spaces) get a little extra breathing room.
        if not row.startswith(" "):
            y -= _SECTION_GAP
        placements.append((_LEFT_X, y, row))
        y -= _ROW_STEP

    return _render_pdf(placements)


__all__ = ["OwnerReport", "build_owner_report", "render_owner_report_pdf", "REPORT_VERSION"]
