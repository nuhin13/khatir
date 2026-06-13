---
id: T-008
epic: EPIC-13
title: Flag propagation test (<60s)
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-002]
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
- [x] toggle flag → /config/public reflects immediately (cache busted)
- [x] test passes

## 12. Test plan
### Automated
- test_flag_toggle_propagates_to_config_public
## 13. Acceptance criteria
- [x] Propagation test; catches regressions.
## 14. Self-review
- [x] Full chain tested
### Deviations from spec
None. Dedicated `test_flag_propagation.py` added as specified; complements the
inline `test_toggle_reflects_in_config_public` already in `test_flag_endpoints.py`
by providing a single end-to-end both-directions propagation guard.
### Files touched (actual)
- apps/api/khatir/featureflags/tests/test_flag_propagation.py (add)
## 15. Notes
- Pairs with EPIC-12 T-010.
