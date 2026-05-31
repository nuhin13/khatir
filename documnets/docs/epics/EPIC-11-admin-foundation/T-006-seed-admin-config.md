---
id: T-006
epic: EPIC-11
title: Seed admin session config
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
- [ ] seed admin_session_timeout_minutes=60, admin_mfa_required=true
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_admin_config_seeded
## 13. Acceptance criteria
- [ ] Keys seeded; reversible; test passes.
## 14. Self-review
- [ ] Used by T-003
### Deviations from spec
### Files touched (actual)
## 15. Notes
- int + bool types.
