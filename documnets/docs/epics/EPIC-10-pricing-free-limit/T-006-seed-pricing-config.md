---
id: T-006
epic: EPIC-10
title: Seed pricing config keys
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Seed pricing config keys

## 1. Feature goal
Seed `free_tier_tenant_limit` (int, 2) and `nid_verification_tiers` (json).

## 3. What this task DOES
- Seed 2 keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6. Database changes
2 SystemConfig rows.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] free_tier_tenant_limit=2
- [ ] nid_verification_tiers=["bundle_10","bundle_20","bundle_50","unlimited"]
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_pricing_config_seeded
## 13. Acceptance criteria
- [ ] Keys seeded; reversible; test passes.
## 14. Self-review
- [ ] Used by T-003 + T-009
### Deviations from spec
### Files touched (actual)
## 15. Notes
- free_tier_tenant_limit int; nid_verification_tiers json list.
