---
id: T-008
epic: EPIC-11
title: Authenticated shell + session guard (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-007]
blocks: [T-009, T-010, T-011]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Authenticated shell + session guard (Next.js)

## 1. Feature goal
Replace EPIC-00's stub session guard with a real one; complete the authenticated shell (sidebar + topbar) with role-aware nav.

## 2. Business logic
Route guard: no valid session → /login. Session nearing expiry → auto-renew or prompt. Topbar: admin name + role + logout. Sidebar: items per AdminRole (compliance role doesn't see pricing, etc.). Role read from session/me.

## 3. What this task DOES
- Real session guard middleware/HOC; role-aware sidebar; topbar with logout; session timeout warning; tests.

## 5. Files & changes
### Update
- app/(dashboard)/layout.tsx (real guard, topbar, sidebar)
### Add
- lib/auth/admin-session.ts; test

## 6–10.
No DB; consumes /admin/auth/me; surface admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `ui/KhatirAdmin.jsx` dashboard shell + `04_Admin_Portal_Khatir.md` §3.1
- Surface: admin · **Lane:** 🟣 admin
- Authenticated layout wrap
- Role-aware sidebar visibility
- Topbar: name, role badge, logout
- States: authenticated, session expiry warning

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] real session guard (no session → /login)
- [ ] role-aware sidebar (items by role)
- [ ] topbar (name, role, logout)
- [ ] session timeout warning + auto-extend or prompt
- [ ] logout clears session + /login
- [ ] tests: guard redirect, role-aware nav
- [ ] eslint + tsc pass

## 12. Test plan
### Automated
- test_guard_redirect, test_role_nav_visibility
### Manual QA
1. Unauthenticated → /login. Compliance role → no pricing link.

## 13. Acceptance criteria
- [ ] Real session guard; role-aware sidebar; topbar; tests pass.
## 14. Self-review
- [ ] EPIC-00 stub replaced; role logic correct
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Replaces EPIC-00 T-009's stub session guard. Match sidebar items to admin spec §3.1.
