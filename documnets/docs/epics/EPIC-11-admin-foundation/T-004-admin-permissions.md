---
id: T-004
epic: EPIC-11
title: Admin role-based permissions
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-001]
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
- [x] IsAdminUser (validates admin JWT)
- [x] RequiresAdminRole factory
- [x] Role matrix documented in docstring
- [x] Tests: each role allows/denies correct sections
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_role_matrix (parametrized)
## 13. Acceptance criteria
- [x] Admin permission classes; role matrix enforced; tests + lint pass.
## 14. Self-review
- [x] Completely separate from customer permissions
### Deviations from spec
- Added `RequiresAdminSection(section)` + `AdminSection` constants on top of
  `RequiresAdminRole(*roles)`, so views can gate by the §2 section name (which
  expands to the role matrix). `super` is implicitly allowed in every section.
- JWT decoded inline via PyJWT against `ADMIN_JWT_SIGNING_KEY` (HS256), per
  §15 / settings — independent of the customer simplejwt realm. Decode is
  memoised on the request as `request.admin_principal`.
### Files touched (actual)
- `khatir/admin_portal/permissions.py` (add)
- `khatir/admin_portal/tests/test_admin_permissions.py` (add)
## 15. Notes
- Admin JWT payload contains admin_user_id + role. Validate signature with ADMIN_JWT_SIGNING_KEY.
