---
id: T-009
epic: EPIC-09
title: Income-vs-expense chart
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004, T-005]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] two-series chart (income/expense per month)
- [ ] token colors (sage=income, rose=expense)
- [ ] 6-month window
- [ ] empty state
- [ ] integrated into dashboard_screen
- [ ] analyze + test pass (widget test via T-006)

## 12. Test plan
### Automated
- covered by dashboard_screen_test (T-006)
### Manual QA
1. Dashboard shows two-series chart with real income + expense.

## 13. Acceptance criteria
- [ ] Income-vs-expense chart correct + themed; test passes.
## 14. Self-review
- [ ] Sage=income, rose=expense; token colors; correct data mapping
### Deviations from spec
### Files touched (actual)
## 15. Notes
- If the design shows bars, use KBarChart. If line, KLineChart. Follow the prototype.
