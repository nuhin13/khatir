---
id: T-010
epic: EPIC-12
title: Pricing change propagation test
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-001, T-002]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
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
- [x] integration test: edit tier → /config/public reflects change
- [x] test passes
- [x] ruff clean

## 12. Test plan
### Automated
- test_tier_change_propagates_to_config_public
## 13. Acceptance criteria
- [x] Propagation test passes; catches regressions.
## 14. Self-review
- [x] Full chain tested
### Deviations from spec
- Test placed at `khatir/admin_portal/tests/test_propagation.py` (the repo's
  Django app lives under `apps/api/khatir/admin_portal`, not a top-level
  `admin_portal/` package; the path is the project-accurate equivalent of the
  spec's `admin_portal/tests/test_propagation.py`).
### Files touched (actual)
- apps/api/khatir/admin_portal/tests/test_propagation.py (add)
## 15. Notes
- This is the <60s guarantee test.
