---
id: T-012
epic: EPIC-08
title: Expense summary hook for dashboard
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-012 · Expense summary hook for dashboard

## 1. Feature goal
A selector returning expense totals by category + by month, ready for EPIC-09 dashboard charts.

## 2. Business logic
Aggregate expenses (sum by category, by month) scoped to owner. Read-only selector reused by EPIC-09.

## 3. What this task DOES
- expense summary selector + a small endpoint (or part of dashboard endpoint later). Tests on the math.

## 5. Files & changes
### Add
- maintenance/selectors.py, tests/test_expense_summary.py
### Update
- expose via /api/v1/expenses/summary (or leave for EPIC-09 to consume)

## 6. Database changes
None.
## 7. API changes
Optional GET /api/v1/expenses/summary.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] sum by category + by month (annotated)
- [ ] scoped to owner
- [ ] Tests on aggregation
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_summary_by_category, test_summary_by_month
### Manual QA
1. Summary numbers match raw expenses.

## 13. Acceptance criteria
- [ ] Accurate expense summary selector; tests + lint pass.

## 14. Self-review
- [ ] No N+1; scoped
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- EPIC-09 dashboard consumes this. Use ORM aggregation.
