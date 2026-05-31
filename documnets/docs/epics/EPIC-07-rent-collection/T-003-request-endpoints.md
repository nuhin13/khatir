---
id: T-003
epic: EPIC-07
title: Rent-request create + queue endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, EPIC-06.T-002]
blocks: [T-004, T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Rent-request create + queue endpoints

## 1. Feature goal
Create rent requests (from a schedule period or manual one-off) and list the landlord's request queue.

## 2. Business logic
Create generates a link token (T-002), sets status sent (after send T-004), links the schedule period (marks it requested). Queue lists by status. for_user via lease→landlord. Audit.

## 3. What this task DOES
- Create + list/detail endpoints; mark schedule requested; permissions; audit; tests.

## 5. Files & changes
### Add
- rent/{serializers,services,views,urls}.py, tests/test_request_api.py
### Update
- config/urls.py

## 6. Database changes
Writes rent requests; updates schedule status.
## 7. API changes
| POST | /api/v1/rent-requests | owner | 201 |
| GET | /api/v1/rent-requests | owner | 200 |
| GET | /api/v1/rent-requests/{id} | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None (send is T-004).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] create (schedule or manual) + token
- [ ] mark schedule period requested
- [ ] queue list + detail
- [ ] for_user + permissions + audit
- [ ] Tests: create, queue, scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create_from_schedule, test_manual, test_queue, test_scoped
### Manual QA
1. Create request → appears in queue with token.

## 13. Acceptance criteria
- [ ] Request create + queue scoped + audited; tests + lint pass.

## 14. Self-review
- [ ] Token issued; schedule marked; for_user
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Manual one-off requests have rent_schedule null. Sending happens in T-004 (status→sent then).
