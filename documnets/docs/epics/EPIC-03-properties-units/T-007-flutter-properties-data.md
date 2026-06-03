---
id: T-007
epic: EPIC-03
title: Flutter properties data layer (repos, models, providers)
layer: mobile
size: M
status: in-progress
preferred_agent: claude-code
depends_on: [T-003, T-004, T-005]
blocks: [T-009, T-010, T-012, T-013]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Flutter properties data layer (repos, models, providers)

## 1. Feature goal
Typed data layer for buildings/units/portfolio so all property screens share one source.

## 2. Business logic
freezed models matching wire schema; dio repositories; Riverpod providers/controllers exposing AsyncValue. No UI here.

## 3. What this task DOES
- Models: Building, Unit, PortfolioSummary (freezed).
- Repositories: buildings, units (incl. generate), portfolio.
- Providers/controllers. Unit tests (mocked dio).

## 5. Files & changes
### Add
- `features/properties/data/models/*.dart`
- `features/properties/data/{building_repository,unit_repository,portfolio_repository}.dart`
- `features/properties/data/properties_providers.dart`
- `test/properties_repo_test.dart`

## 6. Database changes
None.
## 7. API changes
Consumes buildings/units/portfolio endpoints.
## 8. UI changes
No UI (data layer).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] freezed Building/Unit/PortfolioSummary models (+ Area/UnitType/UnitStatus/UnitScheme enums)
- [x] building/unit/portfolio repositories (dio)
- [x] generate units repo method
- [x] providers/controllers (AsyncValue)
- [x] Tests (mocked dio)
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment

## 12. Test plan
### Automated
- test_fetch_buildings/units/portfolio; test_generate_units
### Manual QA
1. Wire a temp screen to list buildings.

## 13. Acceptance criteria
- [~] Typed data layer covering all property endpoints; tests written.
  analyze/test NOT verified — no Flutter/Dart toolchain available in this env.

## 14. Self-review
- [x] Wire schema matches backend (snake_case keys parsed in static `fromJson`)
### Deviations from spec
- Models use a static `fromJson` (not a `@freezed` json-codegen factory),
  matching the project's `Profile`/`SessionUser` precedent: `lat`/`lng`/`rent`/
  `total_rent` arrive as DRF `DecimalField` **strings** and the enums are typed,
  so manual parsing avoids pulling json_serializable in for these models and
  keeps decimal-string → `double` and wire → enum mapping explicit. No `.g.dart`
  files are generated for them.
- Property-domain enums (`Area`/`UnitType`/`UnitStatus`/`UnitScheme`) live in
  `features/properties/data/models/property_enums.dart` (owning feature),
  mirroring the backend convention of domain enums in the owning app rather than
  `core/`.
- **Blocker:** no Flutter/Dart toolchain exists in this environment
  (`flutter`/`dart` not on PATH; the `~/Downloads/flutter` referenced by the
  shell profile is absent), so `build_runner`, `flutter analyze`, and
  `flutter test` could not be run. The freezed `*.freezed.dart` parts were
  hand-written to faithfully match freezed 3.x codegen output (validated
  field-by-field against the committed `profile.freezed.dart` and
  `auth_state.freezed.dart`), and Riverpod 2.6.1 / freezed_annotation APIs were
  verified against the pub cache. The DoD test-pass gate therefore cannot be
  confirmed; status set to `in-progress` per the finish protocol (same blocker
  as EPIC-02/T-008 and EPIC-03/T-008).
### Files touched (actual)
- Add: `lib/features/properties/data/models/property_enums.dart`
- Add: `lib/features/properties/data/models/building.dart` (+ `.freezed.dart`)
- Add: `lib/features/properties/data/models/unit.dart` (+ `.freezed.dart`)
- Add: `lib/features/properties/data/models/portfolio_summary.dart` (+ `.freezed.dart`)
- Add: `lib/features/properties/data/building_repository.dart`
- Add: `lib/features/properties/data/unit_repository.dart`
- Add: `lib/features/properties/data/portfolio_repository.dart`
- Add: `lib/features/properties/data/properties_providers.dart`
- Add: `test/properties_repo_test.dart`
- Update: `lib/core/network/api_endpoints.dart` (buildings/units/portfolio paths)

## 15. Notes for the implementing agent
- Keep models aligned with enums.md (UnitType/UnitStatus as Dart enums with @JsonValue).
