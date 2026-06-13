---
id: T-003
epic: EPIC-03
title: Building CRUD endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-005, T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Building CRUD endpoints

## 1. Feature goal
CRUD for buildings, scoped to the user, so the app can create/list/update/delete buildings.

## 2. Business logic
Owner set from request.user on create. All reads via for_user. Address required; lat/lng optional. Audit on create/update/delete.

## 3. What this task DOES
- Serializers; service functions; viewset/views; urls under /api/v1/buildings.
- Permissions (IsLandlordOrManager + IsOwnerOfBuilding).
- Audit. Tests (happy + auth-fail + validation-fail + cross-user 404).

## 4. What this task does NOT do
- Units (T-004); portfolio aggregation (T-005).

## 5. Files & changes
### Add
- `properties/serializers.py`, `services.py`, `views.py`, `urls.py`
- `properties/tests/test_building_api.py`
### Update
- `config/urls.py` — include properties urls

## 6. Database changes
None beyond writes.

## 7. API changes
| Method | Path | Auth | Status |
|--------|------|------|--------|
| GET | /api/v1/buildings | Bearer | 200 |
| POST | /api/v1/buildings | Bearer landlord/mgr | 201 |
| GET | /api/v1/buildings/{id} | Bearer owner | 200 |
| PATCH | /api/v1/buildings/{id} | Bearer owner | 200 |
| DELETE | /api/v1/buildings/{id} | Bearer owner | 204 |

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] BuildingSerializer (+ create/update)
- [x] services create/update/delete with audit
- [x] viewset scoped via for_user
- [x] permissions attached
- [x] urls under /api/v1/buildings
- [x] Tests: CRUD happy, auth-fail, validation, cross-user 404
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_create/list/retrieve/update/delete; test_cross_user_404; test_address_required
### Manual QA
1. Create + list buildings as a landlord.

## 13. Acceptance criteria
- [x] CRUD works, scoped, audited; tests + lint pass.

## 14. Self-review
- [x] for_user on all reads; owner set server-side; audited
### Deviations from spec
- None. Buildings are mounted at `/api/v1/buildings` via a `DefaultRouter`
  (`trailing_slash=False`) to honour the project's no-trailing-slash path
  convention. Tenants reaching the endpoint get 403 (role gate, `IsLandlordOrManager`);
  a landlord/manager addressing another user's building gets 404 (the `for_user`
  scope hides it before the object check), per §15.
### Files touched (actual)
- Add: `apps/api/khatir/properties/serializers.py`, `services.py`, `views.py`, `urls.py`
- Add: `apps/api/khatir/properties/tests/test_building_api.py`
- Update: `apps/api/config/urls.py` (include properties urls)

## 15. Notes for the implementing agent
- Never trust client-sent owner; always request.user. Return 404 (not 403) for other users' buildings.
