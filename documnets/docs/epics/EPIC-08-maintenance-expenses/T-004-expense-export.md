---
id: T-004
epic: EPIC-08
title: Expense list + CSV export endpoint
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-003]
blocks: [T-007, T-011]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Expense list + CSV export endpoint

## 1. Feature goal
Filtered expense listing (by building/unit/date range) and a CSV export for tax/record-keeping.

## 2. Business logic
List with filters; CSV export streams the same scoped data. for_user.

## 3. What this task DOES
- List filters + `GET /expenses/export` (CSV). Tests.

## 5. Files & changes
### Add
- export view; tests/test_export.py
### Update
- urls

## 6. Database changes
None.
## 7. API changes
| GET | /api/v1/expenses?building=&unit=&from=&to= | owner | 200 |
| GET | /api/v1/expenses/export | owner | 200 (text/csv) |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] filtered list (building/unit/date)
- [ ] CSV export (scoped)
- [ ] Tests: filters, CSV content, scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_filters, test_csv_export
### Manual QA
1. Export expenses → CSV downloads with correct rows.

## 13. Acceptance criteria
- [ ] Filtered list + CSV export scoped; tests + lint pass.

## 14. Self-review
- [ ] for_user on export; correct CSV headers
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Stream CSV; columns: date, building, unit, category, amount, source, note.
