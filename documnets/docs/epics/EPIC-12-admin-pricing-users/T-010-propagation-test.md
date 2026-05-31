---
id: T-010
epic: EPIC-12
title: Pricing change propagation test
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-001, T-002]
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

# T-010 · Pricing change propagation test

## 1. Feature goal
Assert that a tier change made via the admin API is reflected in /config/public within the cache TTL window.

## 2. Business logic
Integration test: edit tier via admin API → GET /config/public → assert new value present (after cache bust signal fires).

## 3. What this task DOES
- One integration test covering the full chain: edit → cache bust → config/public reflects.

## 5. Files & changes
### Add
- admin_portal/tests/test_propagation.py

## 6–10.
No DB change; integration test only.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] integration test: edit tier → /config/public reflects change
- [ ] test passes
- [ ] ruff clean

## 12. Test plan
### Automated
- test_tier_change_propagates_to_config_public
## 13. Acceptance criteria
- [ ] Propagation test passes; catches regressions.
## 14. Self-review
- [ ] Full chain tested
### Deviations from spec
### Files touched (actual)
## 15. Notes
- This is the <60s guarantee test.
