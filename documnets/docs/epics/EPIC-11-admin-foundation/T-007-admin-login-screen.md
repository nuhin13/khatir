---
id: T-007
epic: EPIC-11
title: Admin login + MFA screen (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-008]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Admin login + MFA screen (Next.js)

## 1. Feature goal
The admin login flow: email+password form → MFA code entry (6-digit TOTP) → authenticated session.

## 2. Business logic
Per admin spec §2. Two-step: credentials → MFA challenge → token stored in HTTP-only cookie or secure storage → redirect to dashboard. Wrong MFA → clear + retry. Account disabled → clear error.

## 3. What this task DOES
- Replace EPIC-00's placeholder `/login` with real form + MFA step; API calls; session cookie; redirect. Tests (RTL or Playwright smoke).

## 5. Files & changes
### Update
- app/login/page.tsx (real form)
### Add
- app/login/mfa/page.tsx; auth API calls; session cookie helper; test

## 6–10.
No DB; consumes admin auth endpoints; surface admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `docs/product/04_Admin_Portal_Khatir.md` §2 + `ui/KhatirAdmin.jsx` login section
- Surface: admin · **Lane:** 🟣 admin
- Routes: `/login`, `/login/mfa`
- Translate login form + MFA step; Notun Din tokens via Tailwind
- States: form, MFA challenge, error (wrong/disabled), loading
- Navigation: success → /dashboard

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] /login: email+password form, POST /login
- [x] MFA challenge → /login/mfa step (6-digit input)
- [x] session token stored (HTTP-only cookie)
- [x] error states (wrong creds, wrong MFA, disabled)
- [x] redirect to /dashboard on success
- [x] test (login flow)
- [x] eslint + tsc + build pass

## 12. Test plan
### Automated
- login form renders; submit calls API; MFA step appears; success redirects
### Manual QA
1. Full login → MFA → dashboard. Wrong MFA → error + retry.

## 13. Acceptance criteria
- [x] Admin login + MFA works; session set; errors handled; tests pass.
## 14. Self-review
- [x] HTTP-only cookie (not localStorage); MFA steps clear
### Deviations from spec
- The browser never sees the admin access token. Both login steps proxy through
  server-side Next route handlers (`app/api/auth/{login,verify-mfa,logout}`)
  which call the EPIC-11.T-003 backend and write the returned token into an
  HTTP-only, SameSite=strict cookie via `lib/auth/session.ts`. The transient
  MFA challenge token is likewise stored in a short-lived HTTP-only cookie
  between steps (read server-side in `/api/auth/verify-mfa`), so it is never
  exposed to client JS — stronger than passing it through the page.
- "Account disabled" / "wrong MFA" are surfaced via the backend's deliberately
  uniform `auth_invalid` message (T-003 hides which factor failed); rate-limit
  (429) and expired-challenge (440 → restart at `/login`) are handled too.
- `lib/auth/guard.ts` now re-exports the cookie constant + `getSession` from the
  new `lib/auth/session.ts` (no behaviour change for the dashboard layout).
### Files touched (actual)
- Update: app/login/page.tsx (real client form), lib/auth/guard.ts (re-export)
- Add: app/login/mfa/page.tsx; lib/auth/session.ts (cookie helpers);
  lib/auth/api.ts (zod-validated backend calls);
  app/api/auth/{login,verify-mfa,logout}/route.ts; test/login.test.tsx

## 15. Notes for the implementing agent
- Use an HTTP-only cookie for the admin token — admin portal is desktop web, cookies are appropriate and safer than localStorage. TOTP window ±30s tolerance.
