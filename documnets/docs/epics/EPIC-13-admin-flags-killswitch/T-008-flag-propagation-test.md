---
id: T-008
epic: EPIC-13
title: Flag propagation test (<60s)
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-002]
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

# T-008 · Flag propagation test (<60s)

## 1. Feature goal
Assert that toggling a flag via the admin API is immediately visible in /config/public.

## 2. Business logic
Same pattern as EPIC-12 T-010: toggle → cache bust → /config/public reflects. This time for flags.

## 3. What this task DOES
- Integration test: toggle flag → GET /config/public → assert flag value updated.

## 5. Files & changes
### Add
- featureflags/tests/test_flag_propagation.py

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] toggle flag → /config/public reflects immediately (cache busted)
- [ ] test passes

## 12. Test plan
### Automated
- test_flag_toggle_propagates_to_config_public
## 13. Acceptance criteria
- [ ] Propagation test; catches regressions.
## 14. Self-review
- [ ] Full chain tested
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Pairs with EPIC-12 T-010.
