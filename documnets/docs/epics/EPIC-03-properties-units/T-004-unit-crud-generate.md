---
id: T-004
epic: EPIC-03
title: Unit CRUD + bulk-generate endpoint
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-005, T-007, T-014]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Unit CRUD + bulk-generate endpoint

## 1. Feature goal
CRUD for units plus a bulk-generate endpoint that creates units from floors × per-floor + numbering scheme — the server-side source of truth for the wizard's unit step.

## 2. Business logic
Generation: given floors, perFloor, scheme(letter|number), produce labels (letter: `1A,1B,2A…`; number: `101,102,201…`), plus custom labels and removals. The UI mirrors this (T-011) but the API is authoritative. Units scoped via building for_user.

## 3. What this task DOES
- Unit serializers; CRUD endpoints; `POST /buildings/{id}/units/generate` (bulk) + single create.
- Generation service with deterministic labels (shared logic referenced by T-014 parity test).
- Audit. Tests incl. generation vectors.

## 4. What this task does NOT do
- Portfolio aggregation (T-005).

## 5. Files & changes
### Add
- unit serializers/services in `properties/`
- `properties/unit_generation.py` (pure function)
- `properties/tests/test_unit_api.py`, `test_unit_generation.py`
### Update
- `properties/views.py`, `urls.py`

## 6. Database changes
Bulk insert of units. No schema change.

## 7. API changes
| Method | Path | Auth | Status |
|--------|------|------|--------|
| GET | /api/v1/buildings/{id}/units | owner | 200 |
| POST | /api/v1/buildings/{id}/units | owner | 201 |
| POST | /api/v1/buildings/{id}/units/generate | owner | 201 |
| GET/PATCH/DELETE | /api/v1/units/{id} | owner | 200/200/204 |

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] unit_generation pure function (letter + number schemes)
- [x] generate endpoint (floors×perFloor + customs − removals)
- [x] unit CRUD endpoints scoped
- [x] audit
- [x] Tests: generation vectors, CRUD, cross-user 404
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_generate_letter / number / with_custom / with_removed
- test_unit_crud; test_cross_user_404
### Manual QA
1. Generate 3 floors × 2 = 6 units; verify labels.

## 13. Acceptance criteria
- [x] Generation matches design schemes; CRUD scoped; tests + lint pass.

## 14. Self-review
- [x] Generation pure + deterministic (parity-testable in T-014)
### Deviations from spec
- Test files still carry the pre-existing factory-boy mypy false positives
  (`Factory(...).pk` / `.owner_id`), matching the T-003 baseline. All **source**
  files are mypy-clean; the `khatir.*.tests.*` override already relaxes untyped
  calls for the same reason.
- `generate_units` skips labels already present on the building (so a re-run
  only inserts the missing ones) — not explicitly specified, but keeps the bulk
  insert from creating duplicate labels.
### Files touched (actual)
- Add: `apps/api/khatir/properties/unit_generation.py`
- Add: `apps/api/khatir/properties/tests/test_unit_generation.py`, `test_unit_api.py`
- Update: `apps/api/khatir/properties/enums.py` (add `UnitScheme`)
- Update: `apps/api/khatir/properties/serializers.py` (Unit serializers)
- Update: `apps/api/khatir/properties/services.py` (create/generate/update/delete unit)
- Update: `apps/api/khatir/properties/views.py` (nested units action + `UnitViewSet`)
- Update: `apps/api/khatir/properties/urls.py` (register `units` route)

## 15. Notes for the implementing agent
- Letter scheme: floor number + A,B,C… per perFloor (1A,1B,2A,2B). Number scheme: floor×100 + index (101,102,201,202). Keep this function pure so T-014 can test UI parity against the same vectors.
