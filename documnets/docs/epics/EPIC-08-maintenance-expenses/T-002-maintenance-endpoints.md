---
id: T-002
epic: EPIC-08
title: Maintenance request + queue + resolve endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
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

# T-002 · Maintenance request + queue + resolve endpoints

## 1. Feature goal
Create maintenance requests, list the landlord's queue, and resolve a request with a cost (which triggers an Expense via T-003).

## 2. Business logic
Create (from tenant/web or landlord). Queue lists open/resolved scoped via unit→building→owner. Resolve sets resolved + cost + note → creates Expense (source=request) idempotently. Audit.

## 3. What this task DOES
- Create/list/detail + resolve endpoints; permissions; audit; tests.

## 5. Files & changes
### Add
- maintenance/{serializers,services,views,urls}.py, tests/test_maintenance_api.py
### Update
- config/urls.py

## 6. Database changes
Writes requests; resolve writes Expense (via T-003).
## 7. API changes
| POST | /api/v1/maintenance-requests | owner/tenant | 201 |
| GET | /api/v1/maintenance-requests | owner | 200 |
| POST | /api/v1/maintenance-requests/{id}/resolve | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] create + queue + detail
- [ ] resolve (cost + note) → Expense (idempotent)
- [ ] for_user + permissions + audit
- [ ] Tests: create, queue, resolve→expense, scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create, test_resolve_creates_expense, test_resolve_idempotent, test_scoped
### Manual QA
1. Create request → resolve with cost → expense appears.

## 13. Acceptance criteria
- [ ] Request/queue/resolve scoped + audited; resolve→expense; tests + lint pass.

## 14. Self-review
- [ ] Resolve creates exactly one expense; for_user
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Resolve must be idempotent (re-resolving doesn't double-create the expense).
