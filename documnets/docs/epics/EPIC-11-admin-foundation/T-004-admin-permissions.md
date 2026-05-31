---
id: T-004
epic: EPIC-11
title: Admin role-based permissions
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001]
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

# T-004 · Admin role-based permissions

## 1. Feature goal
DRF permission classes for admin endpoints, enforcing AdminRole-based access.

## 2. Business logic
Roles and their allowed sections: super = all; ops = users/platform; finance = billing/pricing; compliance = audit/export; support = users(read). Permission class checks the admin JWT + role.

## 3. What this task DOES
- IsAdminUser, RequiresAdminRole(*roles), role constants; tests.

## 5. Files & changes
### Add
- admin_portal/permissions.py, tests/test_admin_permissions.py

## 6–10.
No DB/API changes; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] IsAdminUser (validates admin JWT)
- [ ] RequiresAdminRole factory
- [ ] Role matrix documented in docstring
- [ ] Tests: each role allows/denies correct sections
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_role_matrix (parametrized)
## 13. Acceptance criteria
- [ ] Admin permission classes; role matrix enforced; tests + lint pass.
## 14. Self-review
- [ ] Completely separate from customer permissions
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Admin JWT payload contains admin_user_id + role. Validate signature with ADMIN_JWT_SIGNING_KEY.
