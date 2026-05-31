---
id: T-012
epic: EPIC-01
title: Splash routing + session bootstrap + logout wiring
layer: mobile
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-011]
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

# T-012 · Splash routing + session bootstrap + logout wiring

## 1. Feature goal
Tie the whole EPIC-01 flow together: a splash screen that bootstraps the session and routes correctly (onboarding vs auth vs into the app), plus a working logout that returns the user to the start. This closes the auth loop and proves the epic end-to-end.

## 2. Business logic
- On launch, splash shows briefly while `authController.bootstrap()` runs.
- Routing decision (go_router redirect, reading `authStateProvider` + onboarding-seen flag):
  - onboarding not seen → `/onboarding`
  - seen + Unauthenticated → `/auth/phone`
  - Authenticated → a temporary "/home" placeholder (EPIC-02 replaces with role routing to landlord/manager/tenant shells)
- Logout (temporary entry point button on the placeholder home) clears session → redirect to `/auth/phone`.

## 3. What this task DOES
- `features/splash/splash_screen.dart` (branded splash) + bootstrap call.
- go_router `redirect` logic implementing the decision table above.
- A minimal authenticated placeholder home with a Logout button (EPIC-02 supersedes).
- Remove the EPIC-00 placeholder route if still present.
- Widget/integration test of the redirect decision table.

## 4. What this task does NOT do
- No role chooser / role shells (EPIC-02). Authenticated users land on a single placeholder home for now.

## 5. Files & changes
### Add
- `lib/features/splash/presentation/screens/splash_screen.dart`
- `lib/features/home_placeholder/presentation/screens/home_placeholder_screen.dart` (temp, with Logout)
- `test/router_redirect_test.dart`
### Update
- `lib/core/router/app_router.dart` — `/` splash + redirect logic + `/home` placeholder
- remove EPIC-00 `/placeholder` route
### Delete
- EPIC-00 placeholder screen (superseded)

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `/auth/me` via bootstrap (T-011) and `/auth/logout`.

## 8. UI changes
- **Design source:** screen `splash` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-onboard.js` → `reg('splash')`). Placeholder home is temporary (EPIC-02 replaces with role shells from `home`/`mgrHome`/`tenHome`).
- Surface: mobile · **Lane:** 🟢 mobile
- Screens/routes: `/` (splash), `/home` (temp authenticated placeholder)
- Translate splash layout + composition + copy; values from `packages/design-tokens`
- States: loading (bootstrap), then redirect
- Navigation: decision table above; logout → `/auth/phone`
- i18n keys: `splash_loading`, `home_placeholder_welcome`, `common_logout` (bn + en)

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] splash_screen runs bootstrap()
- [ ] go_router redirect: onboarding/auth/home decision table
- [ ] authenticated placeholder home + Logout button
- [ ] logout clears session → /auth/phone
- [ ] EPIC-00 placeholder route removed
- [ ] ARB bn + en
- [ ] Test: redirect decision table (3 states)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- router_redirect_test → not-seen→onboarding; seen+unauth→phone; auth→home
### Manual QA
1. Fresh install → onboarding → phone → OTP → home.
2. Relaunch → straight to home (session bootstrapped).
3. Logout → phone screen; relaunch → phone screen.

## 13. Acceptance criteria
- [ ] Splash bootstraps + routes per the decision table.
- [ ] Full first-run loop works end-to-end (onboarding→phone→OTP→home).
- [ ] Logout returns to phone and clears session.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Redirect reads single auth source of truth
- [ ] No flicker/loop on launch
- [ ] EPIC-02 can cleanly replace /home with role routing
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep `/home` deliberately minimal — it's a seam EPIC-02 replaces with role-based routing to landlord/manager/tenant shells. Leave a clear `// TODO(EPIC-02) role routing` marker.
- This task is the EPIC-01 validation gate: when it passes, the whole onboarding+auth epic is demonstrably working.
