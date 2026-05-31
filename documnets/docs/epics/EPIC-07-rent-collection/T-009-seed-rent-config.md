---
id: T-009
epic: EPIC-07
title: Seed rent-collection config
layer: backend
size: XS
status: todo
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

# T-009 · Seed rent-collection config

## 1. Feature goal
Seed rent_reminder_cadence_hours, rent_link_token_ttl_hours, payment_proof_types.

## 2. Business logic
Defaults: cadence [24,48], TTL 168h (7d), proof types [bkash_txn, nagad_txn, screenshot, note].

## 3. What this task DOES
- Seed keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6. Database changes
SystemConfig rows.
## 7. API changes
payment_proof_types may surface in /config/public for the web page.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] seed 3 keys with defaults
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_rent_config_seeded
### Manual QA
1. get_config returns defaults.

## 13. Acceptance criteria
- [ ] Config seeded; reversible; test passes.

## 14. Self-review
- [ ] Used by T-002/T-006/T-008
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- cadence + proof_types are json; TTL int.
