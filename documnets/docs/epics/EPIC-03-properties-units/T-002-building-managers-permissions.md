---
id: T-002
epic: EPIC-03
title: Building managers (for_user) + permissions
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-02.T-002]
blocks: [T-003, T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Building managers (for_user) + permissions

## 1. Feature goal
Enforce row-level isolation: a landlord sees only their buildings/units; a manager sees buildings of owners they're linked to. Provide object permissions.

## 2. Business logic
Per `04_coding_conventions.md` §3-4. `Building.objects.for_user(user)` filters by owner (landlord) or linked owners (manager); tenants get none. Units scope via their building. Missing scope = P0 bug.

## 3. What this task DOES
- `properties/managers.py`: BuildingQuerySet/Manager `for_user`; Unit scoping via building.
- `properties/permissions.py`: `IsOwnerOfBuilding`, `IsOwnerOfUnit` (object-level).
- Tests: landlord sees own only; other landlord gets none; manager sees linked owners'.

## 4. What this task does NOT do
- No endpoints (T-003/T-004 consume these).

## 5. Files & changes
### Add
- `khatir/properties/managers.py`, `permissions.py`
- `khatir/properties/tests/test_scoping.py`
### Update
- `properties/models.py` — attach managers

## 6. Database changes
None (query logic only).

## 7. API changes
None.

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] BuildingQuerySet.for_user (landlord=own, manager=linked owners, else none)
- [ ] Unit scoping via building.for_user
- [ ] IsOwnerOfBuilding / IsOwnerOfUnit object permissions
- [ ] Tests: own-only, cross-user empty, manager-linked
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_for_user_landlord_own / other_empty / manager_linked
### Manual QA
1. Two landlords; confirm isolation.

## 13. Acceptance criteria
- [ ] for_user enforced; object perms work; tests + lint pass.

## 14. Self-review
- [ ] No queryset bypasses for_user
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Manager→owner links come from `ManagerOwnerLink` (EPIC-01 T-002 created the model; fully used in EPIC-22). Use `user.managed_owner_ids()` helper or query the link table.
