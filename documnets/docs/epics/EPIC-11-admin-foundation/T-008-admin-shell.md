---
id: T-008
epic: EPIC-11
title: Authenticated shell + session guard (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007]
blocks: [T-009, T-010, T-011]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
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
- [x] real session guard (no session → /login)
- [x] role-aware sidebar (items by role)
- [x] topbar (name, role, logout)
- [x] session timeout warning + auto-extend or prompt
- [x] logout clears session + /login
- [x] tests: guard redirect, role-aware nav
- [x] eslint + tsc pass

## 12. Test plan
### Automated
- test_guard_redirect, test_role_nav_visibility
### Manual QA
1. Unauthenticated → /login. Compliance role → no pricing link.

## 13. Acceptance criteria
- [x] Real session guard; role-aware sidebar; topbar; tests pass.
## 14. Self-review
- [x] EPIC-00 stub replaced; role logic correct
### Deviations from spec
- Real guard resolves the admin server-side: `lib/auth/admin-session.ts`
  `getAuthenticatedAdmin()` reads the T-007 HTTP-only session cookie, then calls
  the backend `GET /admin/api/auth/me` with the bearer token (token never
  reaches the browser) and zod-validates the response. A missing cookie, a
  401/403 (revoked/disabled), an unreachable backend (fail-closed), or a
  disabled account all resolve to null → layout redirects to /login. The layout
  now uses this instead of the bare `getSession`.
- Role → nav matrix in `_nav.ts` (`navForRole`) mirrors the backend
  `admin_portal/permissions.py` SECTION_ROLES and spec §2.1: super sees all;
  ops+support → Users/Support; finance → Pricing; compliance → Features/
  Kill-switch/Compliance; Dashboard+Analytics → every role; Notifications/AI
  providers/System/Admin users/Security stay super-only (no scoped role owns
  them in §2.1).
- Session expiry is read from the JWT `exp` claim (decoded unverified — the
  backend owns the signing key; we only need the timestamp) and surfaced to a
  client `SessionTimeoutWarning` banner that counts down within 5 min, offers
  "Stay signed in" (server refresh re-validates against /me), and routes to
  /login once expired. Backend tokens don't silently auto-extend, so the prompt
  path is used (task allowed "auto-renew OR prompt").
### Files touched (actual)
- Update: app/(dashboard)/layout.tsx (real guard, pass role/name/expiry),
  app/(dashboard)/_nav.ts (roles + navForRole), components/features/sidebar.tsx
  (role prop), components/features/topbar.tsx (name/role badge + logout),
  test/sidebar.test.tsx (role-aware nav tests)
- Add: lib/auth/admin-session.ts (getAuthenticatedAdmin guard);
  components/features/session-timeout-warning.tsx;
  test/admin-session.test.ts; test/topbar.test.tsx

## 15. Notes for the implementing agent
- Replaces EPIC-00 T-009's stub session guard. Match sidebar items to admin spec §3.1.
