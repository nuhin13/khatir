---
id: T-002
epic: EPIC-22
title: ManagerTeamMember model + permissions
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: [b2b_manager_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · ManagerTeamMember model + permissions

## 1. Feature goal
ManagerTeamMember(manager FK, member User FK, role staff/sub_manager, permissions_scope json, status). Defines what each team member can do. Migration + tests.

## 2. Business logic
ManagerTeamMember(manager FK, member User FK, role staff/sub_manager, permissions_scope json, status). Defines what each team member can do. Migration + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/managers/... ; tests.

## 6–10.
DB: as described. Manager-scoped via active ManagerOwnerLink. Audited on writes. No external (notify via EPIC-15). Flag b2b_manager_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Owner-consent gating where applicable (active link only)
- [ ] Audit on writes
- [ ] Tests: happy path + scoping (only active-linked owners)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + active-link scoping
## 13. Acceptance criteria
- [ ] Feature works per goal; consent/scope enforced; audited; tests + lint pass.
## 14. Self-review
- [x] Only active-linked owners accessible; consent respected
### Deviations from spec
- Registered `khatir.managers` in INSTALLED_APPS: T-001 created the app but its
  commit added `khatir.chatbot` instead, leaving managers unregistered (could
  not migrate/test). Fixed so this task could function.
### Files touched (actual)
- apps/api/khatir/managers/enums.py (ManagerTeamMemberRole, ManagerTeamMemberStatus)
- apps/api/khatir/managers/models.py (ManagerTeamMember + queryset + has_permission)
- apps/api/khatir/managers/admin.py (ManagerTeamMemberAdmin)
- apps/api/khatir/managers/migrations/0002_managerteammember.py
- apps/api/khatir/managers/tests/factories.py (ManagerTeamMemberFactory)
- apps/api/khatir/managers/tests/test_team_member.py
- apps/api/config/settings/base.py (register khatir.managers)
## 15. Notes
ManagerTeamMember(manager FK, member User FK, role staff/sub_manager, permissions_scope json, status). Defines what each team member can do. Migration + tests.
