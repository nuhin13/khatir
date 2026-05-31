---
id: T-003
epic: EPIC-06
title: Lease CRUD + lifecycle endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-03.T-002]
blocks: [T-004, T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Lease CRUD + lifecycle endpoints

## 1. Feature goal
CRUD + lifecycle (activate/terminate) for leases, scoped to the owner, generating the schedule on activation.

## 2. Business logic
Create draft → activate (generates schedule T-002) → end/terminate. landlord from request.user. for_user via unit→building→owner. Audit lifecycle transitions.

## 3. What this task DOES
- Serializers, services (create/activate/terminate), endpoints, permissions, audit, tests (lifecycle + scoping).

## 5. Files & changes
### Add
- leases/{serializers,services,views,urls}.py, tests/test_lease_api.py
### Update
- config/urls.py

## 6. Database changes
Writes leases; activation writes schedule.
## 7. API changes
| POST | /api/v1/leases | owner | 201 |
| GET/PATCH | /api/v1/leases/{id} | owner | 200 |
| POST | /api/v1/leases/{id}/activate | owner | 200 |
| POST | /api/v1/leases/{id}/terminate | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] lease serializers + create/activate/terminate services
- [ ] activate generates schedule (T-002)
- [ ] for_user scoping + permissions
- [ ] audit transitions
- [ ] endpoints + urls
- [ ] Tests: lifecycle, schedule-on-activate, cross-user 404
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create_draft, test_activate_generates_schedule, test_terminate, test_scoped
### Manual QA
1. Create + activate lease → schedule exists.

## 13. Acceptance criteria
- [ ] Lease CRUD + lifecycle scoped + audited; activation schedules; tests + lint pass.

## 14. Self-review
- [ ] landlord server-side; for_user; audited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- A unit can have one active lease at a time — validate on activate (no overlapping active lease for the same unit).
