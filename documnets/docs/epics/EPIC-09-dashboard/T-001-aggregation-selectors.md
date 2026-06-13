---
id: T-001
epic: EPIC-09
title: Dashboard aggregation selectors
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-07.T-001, EPIC-08.T-003]
blocks: [T-002, T-010]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Dashboard aggregation selectors

## 1. Feature goal
Pure, performant selectors that compute all dashboard metrics from existing data.

## 2. Business logic
Scoped to owner. Compute: total_collected, total_pending, total_overdue, collection_rate (collected/due), occupancy (occupied/total units), monthly_series (N months of collected+expense), income_vs_expense (totals), top_expense_categories (top 5 by amount), late_payer_count. Single queryset pass where possible; no N+1.

## 3. What this task DOES
- `dashboard/selectors.py`: get_dashboard(user, months) returning a typed dict/dataclass. Uses ORM annotations/aggregations. Tests with fixture data verifying each metric.

## 5. Files & changes
### Add
- khatir/dashboard/{__init__,selectors}.py, tests/test_selectors.py
(minimal app or put selectors in a shared module — document the choice)

## 6. Database changes
None (reads).
## 7. API changes
None (used by T-002).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] collection metrics (collected/pending/overdue/rate)
- [x] occupancy (occupied units / total)
- [x] monthly_series (N months)
- [x] income_vs_expense totals
- [x] top 5 expense categories
- [x] scoped to owner (for_user chain)
- [x] no N+1 (annotation-based)
- [x] tests: each metric correct with fixture data
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_collection_rate, test_occupancy, test_monthly_series, test_expense_categories
### Manual QA
1. Call selectors with real data; verify numbers match raw records.

## 13. Acceptance criteria
- [x] All metrics correct + scoped + no N+1; tests + lint pass.

## 14. Self-review
- [x] Each metric tested; ORM aggregations used
### Deviations from spec
- Created a minimal `khatir.dashboard` app (registered in INSTALLED_APPS, no
  models, no migration) rather than a shared module — keeps the selectors and
  their tests under a clear namespace as the spec permits.
- Returns a typed frozen dataclass `DashboardMetrics` (with nested `MonthPoint`
  / `CategoryTotal`) rather than a plain dict; richer + immutable for T-002.
- `monthly_series` is anchored to `timezone.localdate()` (last N calendar months
  ending this month); rent collected is keyed off `RentSchedule.period`
  (`YYYY-MM`) and expense off `TruncMonth(Expense.date)`.
- `late_payer_count` = distinct leases with ≥1 overdue schedule.
### Files touched (actual)
- khatir/dashboard/{__init__,apps,selectors}.py
- khatir/dashboard/tests/{__init__,test_selectors}.py
- config/settings/base.py (added `khatir.dashboard` to INSTALLED_APPS)

## 15. Notes for the implementing agent
- collection_rate = collected / (collected + pending + overdue) × 100. Empty denominator → 0. monthly_series: last N calendar months, filling 0 for missing months.
