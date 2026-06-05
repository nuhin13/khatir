---
id: T-002
epic: EPIC-25
title: Caretaker assignment + scoping endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-03.T-002]
blocks: []
external_services: []
feature_flags: [gatekeeper_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Caretaker assignment + scoping endpoints

## 1. Feature goal
POST /api/v1/buildings/{id}/caretakers (owner/manager assigns). caretaker_for_user scope: a caretaker sees only assigned buildings' visitors. Permissions + audit. Tests.

## 2. Business logic
POST /api/v1/buildings/{id}/caretakers (owner/manager assigns). caretaker_for_user scope: a caretaker sees only assigned buildings' visitors. Permissions + audit. Tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/gatekeeper/... ; tests.

## 6–10.
DB: as described. Caretaker-scoped to assigned buildings. Audited. No external. Flag gatekeeper_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — POST/GET `/buildings/{id}/caretakers` + DELETE `/{assignment_id}` (assign/list/revoke)
- [x] Caretaker scope (assigned buildings only) where applicable — building resolved via `Building.objects.for_user` (foreign → 404); assignments listed via `CaretakerAssignment.objects.for_user`
- [x] Audit on writes — `caretaker.assign` / `caretaker.revoke` via `core.audit.audit`
- [x] Tests: happy + scoping — `tests/test_caretaker_api.py` (assign/list/revoke, role gate, cross-user 404, flag-off, idempotent re-activate, audit)
- [x] ruff clean

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [x] Feature works per goal; scoped; audited; tests + lint pass.
## 14. Self-review
- [x] Assigned-buildings scope; photo encrypted; conventions
### Deviations from spec
- Endpoints nested under the building (`/buildings/{id}/caretakers[/{assignment_id}]`); routes registered before `properties.urls` so the specific path matches ahead of the buildings router catch-all.
- Revoke is `DELETE /buildings/{id}/caretakers/{assignment_id}` performing a soft status flip to `revoked` (no row delete), so an active assignment can later be re-activated by re-POSTing (honours the `uniq_caretaker_building` constraint).
- `caretaker_id` referencing a non-existent / non-caretaker User surfaces as `validation_error` (400), not 404 (the building is the addressable resource).
- Flag `gatekeeper_enabled` read via a thin `gatekeeper.flags` helper, default **on** until T-012 seeds it; flag-off returns the standard `feature_disabled` 403 envelope.
### Files touched (actual)
- apps/api/khatir/gatekeeper/{flags,permissions,serializers,services,views,urls}.py
- apps/api/khatir/gatekeeper/tests/test_caretaker_api.py
- apps/api/config/urls.py (register gatekeeper routes before properties)
## 15. Notes
POST /api/v1/buildings/{id}/caretakers (owner/manager assigns). caretaker_for_user scope: a caretaker sees only assigned buildings' visitors. Permissions + audit. Tests.
