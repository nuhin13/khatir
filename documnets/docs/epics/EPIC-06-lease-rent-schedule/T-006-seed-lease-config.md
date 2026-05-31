---
id: T-006
epic: EPIC-06
title: Seed due-day/grace config
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

# T-006 · Seed due-day/grace config

## 1. Feature goal
Seed `default_due_day` and `rent_overdue_grace_days` SystemConfig.

## 2. Business logic
Defaults: due_day 5, grace 3. Used by scheduling + overdue.

## 3. What this task DOES
- Seed both keys; test.

## 5. Files & changes
### Add
- seed migration/command; test
## 6. Database changes
Two SystemConfig rows.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] seed default_due_day=5, rent_overdue_grace_days=3
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_lease_config_seeded
### Manual QA
1. get_config returns defaults.

## 13. Acceptance criteria
- [ ] Config seeded; reversible; test passes.

## 14. Self-review
- [ ] Used by T-002/T-005
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- int type both.
