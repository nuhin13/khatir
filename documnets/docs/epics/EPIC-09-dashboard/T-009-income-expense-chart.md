---
id: T-009
epic: EPIC-09
title: Income-vs-expense chart
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-004, T-005]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Income-vs-expense chart

## 1. Feature goal
A grouped bar or line chart showing monthly income vs expenses side-by-side — the financial-health view on the dashboard.

## 2. Business logic
Per dashboard design. Uses monthly_series from /dashboard; two series (income=collected, expense=total expenses per month); 6-month window.

## 3. What this task DOES
- Compose KBarChart (or KLineChart) for two series; map monthly_series data; integrate into dashboard screen.

## 5. Files & changes
### Update
- dashboard_screen.dart — wire the income-vs-expense chart section

## 6–10.
No DB; uses dashboard data; surface mobile 🟢; no external; no flags.

## 8. UI changes
- **Design source:** `dashboard` income-vs-expense region — `reg('dashboard')`
- Surface: mobile · **Lane:** 🟢 mobile
- Grouped bar showing 6-month income (sage) vs expense (rose); token colors
- States: empty (zero data for both) / data
- i18n keys: `dashboard_income_series`, `dashboard_expense_series` (bn + en)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] two-series chart (income/expense per month) — grouped KBarChart, income rod (collected) + expense rod
- [x] token colors (sage=income, rose=expense) — sage/sageDk + rose/roseDk gradients from tokens
- [x] 6-month window — trailing 6 of monthly_series
- [x] empty state — all-zero window → KBarChart empty state
- [x] integrated into dashboard_screen — _IncomeExpenseCard rewritten
- [x] analyze + test pass (widget test via T-006) — dashboard_screen_test + chart_widgets_test green (321 tests)

## 12. Test plan
### Automated
- covered by dashboard_screen_test (T-006)
### Manual QA
1. Dashboard shows two-series chart with real income + expense.

## 13. Acceptance criteria
- [x] Income-vs-expense chart correct + themed; test passes.
## 14. Self-review
- [x] Sage=income, rose=expense; token colors; correct data mapping
### Deviations from spec
- The prototype `reg('dashboard')` shows single-series sage bars (collection rate), not a literal income-vs-expense block; per §15 ("follow the prototype … if bars, use KBarChart") and §8 ("grouped bar showing 6-month income (sage) vs expense (rose)"), implemented as a **grouped two-series KBarChart** (income rod beside expense rod per month) rather than a line chart. T-006 had stubbed this card as a single income KLineChart; that is now replaced.
- Extended the shared `KBarChart` (T-005) with an optional `KBarDatum.secondValue` + token-color overrides so it renders generic grouped bars (income/expense) while staying a thin, token-only fl_chart wrapper. Single-series callers (the collection-rate chart) are unchanged. Grouped mode hides per-bar top value labels to keep the dense two-rod axis readable.
- Added i18n keys `dashboard_income_series` / `dashboard_expense_series` (bn+en) per §8; the older `dashboard_income_legend` / `dashboard_expense_legend` keys remain unused-but-present.
### Files touched (actual)
- Update: apps/mobile/lib/core/widgets/charts/k_bar_chart.dart (optional grouped second series, token color overrides, value-label toggle)
- Update: apps/mobile/lib/features/dashboard/presentation/screens/dashboard_screen.dart (`_IncomeExpenseCard` → grouped two-series chart; dropped KLineChart import)
- Update: apps/mobile/lib/l10n/app_en.arb, app_bn.arb (+ regenerated app_localizations*.dart): dashboard_income_series, dashboard_expense_series
- Update (tests): apps/mobile/test/chart_widgets_test.dart (grouped two-series + single-series rod assertions), test/dashboard_screen_test.dart (series-legend assertions)
## 15. Notes
- If the design shows bars, use KBarChart. If line, KLineChart. Follow the prototype.
