---
id: T-004
epic: EPIC-20
title: Seed warning types config
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
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

# T-004 · Seed warning types config

## 1. Feature goal
Seed `warning_types` config + `warning_disclaimer_text` (bn/en).

## 3. What this task DOES
- Seed keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] seed warning_types + warning_disclaimer_text (bn/en)
- [x] idempotent + reversible
- [x] test

## 12. Test plan
### Automated
- test_warning_config_seeded
## 13. Acceptance criteria
- [x] Config seeded; test passes.
## 14. Self-review
- [x] Disclaimer bilingual
### Deviations from spec
- Seeded as `core` `SystemConfig` keys via data migration `0013_seed_warning_config` (chained off `0012_seed_compliance_config`), matching the existing seed-migration convention (e.g. `area_options`, notifications cost). `SystemConfigType` has no JSON variant, so `warning_types` is a JSON-encoded array stored under `text`.
- Bilingual disclaimer split into two keys `warning_disclaimer_text_en` / `warning_disclaimer_text_bn` (one row per language) rather than a single combined blob, so each is independently admin-tunable.
- `warning_types` mirrors task §15 (includes `property_damage`); the T-001 app enum currently ships 4 of these. Migration duplicates the list (does not import app code) to stay frozen.
### Files touched (actual)
- Add: `apps/api/khatir/core/migrations/0013_seed_warning_config.py`
- Add: `apps/api/khatir/core/tests/test_seed_warning_config.py`
## 15. Notes
- warning_types: late_rent, lease_violation, noise, property_damage, other.
