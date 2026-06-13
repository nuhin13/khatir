---
id: T-002
epic: EPIC-08
title: Maintenance CRUD + resolve→auto-expense
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-03.T-002]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Maintenance CRUD + resolve→auto-expense

## 1. Feature goal
Maintenance request CRUD + a resolve action that records cost and auto-creates an Expense (source=request).

## 2. Business logic
Resolve(cost, note) → status resolved + resolution fields + create Expense(source=request, amount=cost, unit). Idempotent (one expense per resolve). for_user via unit. Audit.

## 3. What this task DOES
- CRUD + resolve service (auto-expense) + queue endpoint + permissions + audit + tests.

## 5. Files & changes
### Add
- maintenance/{serializers,services,views,urls}.py, tests/test_maintenance_api.py
### Update
- config/urls.py

## 6. Database changes
Writes maintenance + (on resolve) expense.
## 7. API changes
| GET/POST | /api/v1/maintenance | owner | 200/201 |
| GET | /api/v1/maintenance/{id} | owner | 200 |
| POST | /api/v1/maintenance/{id}/resolve | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] maintenance CRUD + queue
- [ ] resolve → status + auto-expense (idempotent)
- [ ] for_user + permissions + audit
- [ ] Tests: create, resolve→expense once, scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_resolve_creates_one_expense, test_queue, test_scoped
### Manual QA
1. Resolve a request → expense appears.

## 13. Acceptance criteria
- [ ] Maintenance CRUD + resolve→auto-expense (idempotent), scoped, audited; tests + lint pass.

## 14. Self-review
- [ ] Exactly one expense per resolve; for_user
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Guard against double-resolve creating two expenses.
