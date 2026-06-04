---
id: T-004
epic: EPIC-13
title: Seed 5 named kill-switches + default flags
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Seed 5 named kill-switches + default flags

## 1. Feature goal
Seed the 5 legally-required kill-switches and default feature flags (incl. voice_tenant_entry referenced by EPIC-04).

## 2. Business logic
Kill-switches (all enabled by default — switching OFF disables the feature): warnings_feature, reviews_feature, history_flags_feature, free_text_feature, master_kill_switch. Default feature flags: voice_tenant_entry (true), dmp_enabled (true).

## 3. What this task DOES
- Seed migration/command for 5 kill-switch flags + voice/dmp flags. Idempotent. Tests.

## 5. Files & changes
### Add
- seed migration/command; tests

## 6. Database changes
7 FeatureFlag rows.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] 5 kill-switch flags (enabled=true by default)
- [x] voice_tenant_entry + dmp_enabled flags
- [x] idempotent + reversible
- [x] Tests: flags seeded

## 12. Test plan
### Automated
- test_flags_seeded
## 13. Acceptance criteria
- [x] 7 flags seeded; idempotent; test passes.
## 14. Self-review
- [x] All 5 kill-switch keys correct
### Deviations from spec
- Seed auto-run is a no-op under the test settings module (`config.settings.test`); `test_seed_flags` invokes `seed_flags()` directly to verify it. Rationale: the already-committed EPIC-13.T-002/T-003 flag-endpoint tests assert against an empty flags table and build their own rows with these exact keys (`voice_tenant_entry`, `dmp_enabled`, …), so auto-seeding into the test DB would break them. Dev/prod always run the seed in full.
### Files touched (actual)
- Add: `apps/api/khatir/featureflags/migrations/0002_seed_flags.py`
- Add: `apps/api/khatir/featureflags/tests/test_seed_flags.py`
## 15. Notes
- Kill-switch enabled=true = feature IS on (toggle to false = kill it). Be clear about this convention in the seed.
