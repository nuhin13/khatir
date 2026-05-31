---
id: T-007
epic: EPIC-11
title: Admin login + MFA screen (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] /login: email+password form, POST /login
- [ ] MFA challenge → /login/mfa step (6-digit input)
- [ ] session token stored (HTTP-only cookie)
- [ ] error states (wrong creds, wrong MFA, disabled)
- [ ] redirect to /dashboard on success
- [ ] test (login flow)
- [ ] eslint + tsc + build pass

## 12. Test plan
### Automated
- login form renders; submit calls API; MFA step appears; success redirects
### Manual QA
1. Full login → MFA → dashboard. Wrong MFA → error + retry.

## 13. Acceptance criteria
- [ ] Admin login + MFA works; session set; errors handled; tests pass.
## 14. Self-review
- [ ] HTTP-only cookie (not localStorage); MFA steps clear
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use an HTTP-only cookie for the admin token — admin portal is desktop web, cookies are appropriate and safer than localStorage. TOTP window ±30s tolerance.
