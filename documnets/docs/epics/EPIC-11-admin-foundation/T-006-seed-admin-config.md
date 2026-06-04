---
id: T-006
epic: EPIC-11
title: Seed admin session config
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

# T-006 · Seed admin session config

## 1. Feature goal
Seed `admin_session_timeout_minutes` (60) and `admin_mfa_required` (true).

## 3. What this task DOES
- Seed 2 keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6. Database changes
2 SystemConfig rows.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] seed admin_session_timeout_minutes=60, admin_mfa_required=true
- [x] idempotent + reversible
- [x] test
- [x] ruff clean

## 12. Test plan
### Automated
- test_admin_config_seeded
## 13. Acceptance criteria
- [x] Keys seeded; reversible; test passes.
## 14. Self-review
- [x] Used by T-003
### Deviations from spec
None.
### Files touched (actual)
- apps/api/khatir/core/migrations/0009_seed_admin_config.py (new)
- apps/api/khatir/core/tests/test_seed_admin_config.py (new)
## 15. Notes
- int + bool types.
