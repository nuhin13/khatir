---
id: T-001
epic: EPIC-03
title: Building + Unit models, enums, migrations
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-002, T-003, T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Building + Unit models, enums, migrations

## 1. Feature goal
Create the `properties` app with `Building` and `Unit` models — the structural spine all property data hangs off.

## 2. Business logic
Per `06_database_schema.md` Domain 2. Building belongs to an owner (PROTECT). Unit belongs to a building (CASCADE). Money is Decimal(12,2). Status fields are enums. Soft-delete on both (user-facing records).

## 3. What this task DOES
- `properties` app with `Building` (owner, name, area, address, lat, lng) and `Unit` (building, label, type, rent, amenities, status, available_from).
- Enums `Area`, `UnitType`, `UnitStatus` in `properties/enums.py` matching `enums.md`.
- Inherit TimeStampedModel + SoftDeleteModel.
- Indexes: Building(owner), Unit(building, status).
- Django admin registration. Migration. Model tests + factories.

## 4. What this task does NOT do
- No endpoints (T-003/T-004), no `for_user` managers (T-002).

## 5. Files & changes
### Add
- `khatir/properties/{__init__,apps,models,enums,admin}.py`
- `khatir/properties/migrations/0001_initial.py`
- `khatir/properties/tests/{test_models,factories}.py`
### Update
- `config/settings/base.py` — register `khatir.properties`

## 6. Database changes
Creates `properties_building`, `properties_unit`. Reversible. Indexes as above.

## 7. API changes
No endpoints.

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] Building model (owner PROTECT, fields, soft-delete, timestamps)
- [x] Unit model (building CASCADE, rent Decimal, status enum)
- [x] Area/UnitType/UnitStatus enums match enums.md
- [x] Indexes added
- [x] Admin registration
- [x] Migration (reversible)
- [x] Factories + model tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_building_create / soft_delete
- test_unit_create / rent_is_decimal / status_enum
### Manual QA
1. Create building+unit in Django admin.

## 13. Acceptance criteria
- [x] Models per schema; migration applies clean; tests + lint pass.

## 14. Self-review
- [x] Enums match enums.md; money Decimal; soft-delete present
### Deviations from spec
None.
### Files touched (actual)
- `apps/api/khatir/properties/{__init__,apps,models,enums,admin}.py`
- `apps/api/khatir/properties/migrations/{__init__,0001_initial}.py`
- `apps/api/khatir/properties/tests/{__init__,test_models,factories}.py`
- `apps/api/config/settings/base.py` (registered `khatir.properties`)

## 15. Notes for the implementing agent
- `amenities` is jsonb (list). `available_from` nullable. Don't add `for_user` here — that's T-002.
