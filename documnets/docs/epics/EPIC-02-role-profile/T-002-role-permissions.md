---
id: T-002
epic: EPIC-02
title: Role enum + permission helpers (role gating base)
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-01.T-002]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Role enum + permission helpers (role gating base)

## 1. Feature goal
Provide the reusable DRF permission classes that gate endpoints by role, so every later epic composes them instead of writing inline role checks.

## 2. Business logic
Per `04_coding_conventions.md` §4: permissions are explicit classes, never inline `if request.user.role==`. The `Role` enum already exists (EPIC-01 T-002). This task adds the base permission classes used across the app.

## 3. What this task DOES
- In `core/permissions.py` (or `accounts/permissions.py` if user-specific): `IsLandlord`, `IsManager`, `IsTenant`, `IsLandlordOrManager`, and a generic `HasRole(*roles)` factory.
- Unit tests for each (allow/deny by role).
- Document the composition pattern (`&`, `|`) with an example in the module docstring.

## 4. What this task does NOT do
- No object-level ownership permissions (those are per-domain, e.g. `IsOwnerOfBuilding` in EPIC-03).
- No endpoints.

## 5. Files & changes
### Add
- role permission classes in `core/permissions.py` (extend the base from EPIC-00 T-005)
- `core/tests/test_permissions.py`
### Update
- none
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No endpoints (reusable classes).

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] IsLandlord / IsManager / IsTenant / IsLandlordOrManager
- [x] HasRole(*roles) factory
- [x] Module docstring with composition example
- [x] Tests: each class allows correct role, denies others
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_is_landlord_allows_landlord_denies_others (parametrized across classes)
- test_has_role_factory
### Manual QA
- n/a (covered by units)

## 13. Acceptance criteria
- [x] Role permission classes available + tested.
- [x] Composition pattern documented.
- [x] Tests + lint pass.

## 14. Self-review
- [x] No inline role checks introduced elsewhere
- [x] Classes reusable + tested
### Deviations from spec
- Classes live in `khatir.core.permissions` (extending the EPIC-00 base there), not a new
  `accounts/permissions.py` — matches the spec's "extend the base from EPIC-00 T-005" note and
  §15 ("keep these in core so every app imports from one place").
- The pre-existing single-role base was `HasRole` with a single `required_role`. To satisfy the
  spec's generic `HasRole(*roles)` *factory*, the base class was renamed `RoleBasedPermission`
  (now `required_roles: tuple`) and `HasRole` is a factory returning a permission class. No
  external code imported the old name (verified by grep), so this is non-breaking.
- Added `IsLandlordOrManager` (was missing).
### Files touched (actual)
- `apps/api/khatir/core/permissions.py`
- `apps/api/khatir/core/tests/test_permissions.py`

## 15. Notes for the implementing agent
- Read role from `request.user.role` (DB truth), not the token claim, to avoid stale-role bugs after a role switch.
- Keep these in `core` so every app imports from one place.
