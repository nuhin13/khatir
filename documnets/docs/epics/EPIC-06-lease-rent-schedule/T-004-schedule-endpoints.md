---
id: T-004
epic: EPIC-06
title: Schedule endpoints + unit current-lease
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-002, T-003]
blocks: [T-007]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
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
- [x] schedule endpoint (scoped)
- [x] unit current-lease endpoint
- [x] Tests: schedule list, current lease, none→404
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_schedule_list, test_unit_current_lease
### Manual QA
1. GET schedule for an active lease.

## 13. Acceptance criteria
- [x] Schedule + current-lease endpoints scoped; tests + lint pass.

## 14. Self-review
- [x] for_user applied
### Deviations from spec
- `GET /units/{id}/lease` is exposed as a router `@action` on the existing
  `UnitViewSet` (matches T-004 buildings/units convention) rather than a new
  view; the unit's active lease is resolved via `Lease.objects.for_user`, so
  scoping is double-applied (unit + lease).
### Files touched (actual)
- `apps/api/khatir/leases/selectors.py` (new) — `schedule_for_lease`, `active_lease_for_unit`
- `apps/api/khatir/leases/serializers.py` — `RentScheduleSerializer`, `LeaseTenantSummarySerializer`, `UnitLeaseSerializer`
- `apps/api/khatir/leases/views.py` — `schedule` action on `LeaseViewSet`
- `apps/api/khatir/properties/views.py` — `lease` action on `UnitViewSet`
- `apps/api/khatir/leases/tests/test_schedule_api.py` (new)

## 15. Notes for the implementing agent
- current-lease returns the single active lease for the unit (or 404).
