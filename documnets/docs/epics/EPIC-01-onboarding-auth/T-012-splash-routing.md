---
id: T-012
epic: EPIC-01
title: Splash routing + session bootstrap + logout wiring
layer: mobile
size: S
status: done
preferred_agent: claude-code
depends_on: [T-011]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
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
- [x] splash_screen runs bootstrap()
- [x] go_router redirect: onboarding/auth/home decision table
- [x] authenticated placeholder home + Logout button
- [x] logout clears session → /auth/phone
- [x] EPIC-00 placeholder route removed
- [x] ARB bn + en
- [x] Test: redirect decision table (3 states)
- [x] analyze + test pass

## 12. Test plan
### Automated
- router_redirect_test → not-seen→onboarding; seen+unauth→phone; auth→home
### Manual QA
1. Fresh install → onboarding → phone → OTP → home.
2. Relaunch → straight to home (session bootstrapped).
3. Logout → phone screen; relaunch → phone screen.

## 13. Acceptance criteria
- [x] Splash bootstraps + routes per the decision table.
- [x] Full first-run loop works end-to-end (onboarding→phone→OTP→home).
- [x] Logout returns to phone and clears session.
- [x] Test + analyze pass.

## 14. Self-review
- [x] Redirect reads single auth source of truth (authControllerProvider + onboardingSeenProvider)
- [x] No flicker/loop on launch (unknown/loading holds on splash; idempotent redirect targets)
- [x] EPIC-02 can cleanly replace /home with role routing (single `/home` seam, marked with TODO)
### Deviations from spec
- Splash performs no artificial delay; it stays mounted only while bootstrap is `loading` (avoids a fixed timer / flicker). Bootstrap is driven by `AuthController.build()` (T-011), so the splash just subscribes.
- OTP success route now points at `/home`; the AuthState-driven redirect would route there on its own, the explicit `context.go` keeps the transition immediate.
### Files touched (actual)
- Add: `lib/features/home_placeholder/presentation/screens/home_placeholder_screen.dart`
- Add: `test/router_redirect_test.dart`
- Update: `lib/core/router/app_router.dart` (redirect + refreshListenable + onboardingSeenProvider + `/home` route; `/placeholder` removed)
- Update: `lib/features/splash/presentation/screens/splash_screen.dart` (branded splash, subscribes to bootstrap)
- Update: `lib/features/auth/presentation/screens/otp_entry_screen.dart` (success → `/home`)
- Update: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb` (`splash_loading`, `home_placeholder_welcome`, `common_logout`)
- Update: `test/theme_i18n_test.dart` (retargeted off the removed EPIC-00 placeholder)
- Delete: `lib/features/placeholder/presentation/screens/placeholder_screen.dart`

## 15. Notes for the implementing agent
- Keep `/home` deliberately minimal — it's a seam EPIC-02 replaces with role-based routing to landlord/manager/tenant shells. Leave a clear `// TODO(EPIC-02) role routing` marker.
- This task is the EPIC-01 validation gate: when it passes, the whole onboarding+auth epic is demonstrably working.
