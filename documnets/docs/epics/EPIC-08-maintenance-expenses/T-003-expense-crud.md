---
id: T-003
epic: EPIC-08
title: Expense CRUD + CSV export
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-007, T-012]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Expense CRUD + CSV export

## 1. Feature goal
Manual expense CRUD + a CSV export of expenses per building/unit/date range.

## 2. Business logic
Manual expenses (source=manual). List filterable by building/unit/date. CSV export scoped to owner. Audit on create/update/delete.

## 3. What this task DOES
- Expense CRUD + filtered list + CSV export endpoint + permissions + audit + tests.

## 5. Files & changes
### Add
- maintenance/expense_views.py, serializers, tests/test_expense_api.py
### Update
- urls

## 6. Database changes
Writes expenses.
## 7. API changes
| GET/POST | /api/v1/expenses | owner | 200/201 |
| GET/PATCH/DELETE | /api/v1/expenses/{id} | owner | 200/200/204 |
| GET | /api/v1/expenses/export | owner | 200 (CSV) |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] expense CRUD (manual)
- [ ] filtered list (building/unit/date)
- [ ] CSV export scoped
- [ ] permissions + audit
- [ ] Tests: CRUD, filter, export, scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_expense_crud, test_filter, test_csv_export, test_scoped
### Manual QA
1. Add expense; export CSV.

## 13. Acceptance criteria
- [ ] Expense CRUD + filtered list + CSV export scoped + audited; tests + lint pass.

## 14. Self-review
- [ ] CSV scoped; money Decimal; audited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Stream CSV for large sets. Combine with auto-expenses (source=request) from T-002 in listings.
