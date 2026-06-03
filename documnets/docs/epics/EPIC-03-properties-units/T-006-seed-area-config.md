---
id: T-006
epic: EPIC-03
title: Seed area_options SystemConfig
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: [T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Seed area_options SystemConfig

## 1. Feature goal
Make the Dhaka area list admin-configurable instead of hardcoded, seeded from the Area enum.

## 2. Business logic
`area_options` SystemConfig (text/json) holds the selectable areas; exposed via /config/public so the wizard reads it. Default = the Area enum values.

## 3. What this task DOES
- Seed `area_options` (data migration / seed command) with the Area list (Uttara, Mirpur, …, Other).
- Expose in `/config/public`.
- Test.

## 5. Files & changes
### Add
- seed migration/command; test
### Update
- `/config/public` view

## 6. Database changes
Insert one SystemConfig row. Reversible.

## 7. API changes
Adds `config.area_options` to /config/public.

## 8. UI changes
No UI changes.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] Seed area_options from Area enum
- [x] Exposed in /config/public
- [x] Idempotent + reversible
- [x] Test
- [x] ruff clean

## 12. Test plan
### Automated
- test_area_options_in_public_config
### Manual QA
1. GET /config/public shows areas.

## 13. Acceptance criteria
- [x] area_options seeded + public; reversible; test passes.

## 14. Self-review
- [x] Default matches Area enum
### Deviations from spec
- `SystemConfigType` has no `json` variant, so `area_options` is stored as `text`
  holding a JSON-encoded array; the view parses it back to a list.
- Added a frozen `Area` TextChoices enum in `khatir/core/enums.py` (no properties
  app exists yet); the migration mirrors the values per Django migration hygiene.
### Files touched (actual)
- apps/api/khatir/core/enums.py (add `Area`)
- apps/api/khatir/core/migrations/0003_seed_area_options.py (new)
- apps/api/khatir/health/views.py (expose `area_options`)
- apps/api/khatir/core/tests/test_seed_area_options.py (new)
- apps/api/tests/test_healthz.py (add `test_area_options_in_public_config`)

## 15. Notes for the implementing agent
- Areas from enums.md Area: uttara, mirpur, mohammadpur, dhanmondi, banasree, gulshan, banani, bashundhara, old_dhaka, other.
