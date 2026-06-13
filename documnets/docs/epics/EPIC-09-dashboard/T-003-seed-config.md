---
id: T-003
epic: EPIC-09
title: Seed dashboard config
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

# T-003 · Seed dashboard config

## 1. Feature goal
Seed `dashboard_months_default` (int, 6).

## 3. What this task DOES
- Seed key; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6. Database changes
One SystemConfig row.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9–10. External services / Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] seed dashboard_months_default=6
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_config_seeded

## 13. Acceptance criteria
- [ ] Config seeded; test passes.

## 14. Self-review
- [ ] Used by T-002
### Deviations from spec
### Files touched (actual)

## 15. Notes
- int type.
