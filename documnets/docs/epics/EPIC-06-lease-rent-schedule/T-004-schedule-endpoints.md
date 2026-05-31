---
id: T-004
epic: EPIC-06
title: Schedule endpoints + unit current-lease
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-002, T-003]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Schedule endpoints + unit current-lease

## 1. Feature goal
Expose a lease's rent schedule and the current active lease for a unit (so unit detail can show it).

## 2. Business logic
GET schedule (scoped); GET unit's active lease + tenant summary. Read-only.

## 3. What this task DOES
- `GET /leases/{id}/schedule`, `GET /units/{id}/lease`. Tests.

## 5. Files & changes
### Add
- views/selectors + tests
### Update
- urls

## 6. Database changes
None.
## 7. API changes
| GET | /api/v1/leases/{id}/schedule | owner | 200 |
| GET | /api/v1/units/{id}/lease | owner | 200 (or 404 none) |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] schedule endpoint (scoped)
- [ ] unit current-lease endpoint
- [ ] Tests: schedule list, current lease, none→404
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_schedule_list, test_unit_current_lease
### Manual QA
1. GET schedule for an active lease.

## 13. Acceptance criteria
- [ ] Schedule + current-lease endpoints scoped; tests + lint pass.

## 14. Self-review
- [ ] for_user applied
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- current-lease returns the single active lease for the unit (or 404).
