---
id: T-005
epic: EPIC-17
title: Seed verification config + flag
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005, EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [nid_verification_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Seed verification config + flag

## 1. Feature goal
Seed the `nid_verification_enabled` feature flag and EC provider config keys.

## 2. Business logic
Flag default on. Config: ec_verification_provider, ec_verification_endpoint, ec_verification_dpa_reference (required before live use).

## 3. What this task DOES
- Seed flag + config keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6–10.
SystemConfig + FeatureFlag rows.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] seed nid_verification_enabled flag (on) — featureflags/0003_seed_nid_verification_flag
- [x] seed ec provider config keys — core/0014_seed_verification_config
- [x] idempotent + reversible
- [x] test — verification/tests/test_seed_verification_config.py
- [x] ruff clean

## 12. Test plan
### Automated
- test_verification_config_seeded
## 13. Acceptance criteria
- [x] Flag + config seeded; reversible; test passes.
## 14. Self-review
- [x] DPA reference key present (required before live)
### Deviations from spec
### Files touched (actual)
## 15. Notes
- ec_verification_dpa_reference must be set before the provider can go live.
