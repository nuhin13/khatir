---
id: T-001
epic: EPIC-13
title: FeatureFlag + KillSwitchEvent models
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-002, T-003, T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · FeatureFlag + KillSwitchEvent models

## 1. Feature goal
Create FeatureFlag and KillSwitchEvent models.

## 2. Business logic
FeatureFlag(key unique, description, scope GlobalRoleUser, enabled bool, value_json, updated_by FK AdminUser, updated_at). KillSwitchEvent(switch_key, action, reason, admin_user FK AdminUser, lawyer_reference, created_at — immutable).

## 3. What this task DOES
- featureflags app; both models; migrations; admin; tests.

## 5. Files & changes
### Add
- khatir/featureflags/{__init__,apps,models,enums}.py, migrations, tests/factories
### Update
- settings register

## 6. Database changes
2 tables. Reversible.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] FeatureFlag (key unique, scope enum, enabled, value_json)
- [ ] KillSwitchEvent (immutable — no update/delete)
- [ ] updated_by / admin_user FK AdminUser
- [ ] migrations reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_flag_create, test_killswitch_immutable
## 13. Acceptance criteria
- [ ] Models; migration clean; tests + lint pass.
## 14. Self-review
- [ ] KillSwitchEvent immutable; AdminUser FK
### Deviations from spec
### Files touched (actual)
## 15. Notes
- KillSwitchEvent is an append-only log — never edited.
