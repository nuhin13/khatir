---
id: T-007
epic: EPIC-03
title: Flutter properties data layer (repos, models, providers)
layer: mobile
size: M
status: todo
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
- [ ] freezed Building/Unit/PortfolioSummary models
- [ ] building/unit/portfolio repositories (dio)
- [ ] generate units repo method
- [ ] providers/controllers (AsyncValue)
- [ ] Tests (mocked dio)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_fetch_buildings/units/portfolio; test_generate_units
### Manual QA
1. Wire a temp screen to list buildings.

## 13. Acceptance criteria
- [ ] Typed data layer covering all property endpoints; tests + analyze pass.

## 14. Self-review
- [ ] Wire schema matches backend (snake_case via JsonKey)
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep models aligned with enums.md (UnitType/UnitStatus as Dart enums with @JsonValue).
