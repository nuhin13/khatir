---
id: T-004
epic: EPIC-13
title: Seed 5 named kill-switches + default flags
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001]
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
- [ ] 5 kill-switch flags (enabled=true by default)
- [ ] voice_tenant_entry + dmp_enabled flags
- [ ] idempotent + reversible
- [ ] Tests: flags seeded

## 12. Test plan
### Automated
- test_flags_seeded
## 13. Acceptance criteria
- [ ] 7 flags seeded; idempotent; test passes.
## 14. Self-review
- [ ] All 5 kill-switch keys correct
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Kill-switch enabled=true = feature IS on (toggle to false = kill it). Be clear about this convention in the seed.
