---
id: T-008
epic: EPIC-02
title: Router role-redirect guards + replace EPIC-01 /home seam
layer: mobile
size: S
status: in-progress
preferred_agent: claude-code
depends_on: [T-004, T-005]
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

# T-008 · Router role-redirect guards + replace EPIC-01 /home seam

## 1. Feature goal
Finish the routing story: replace the temporary `/home` placeholder EPIC-01 left, and add go_router redirect guards so users land in the right place based on auth + role, and can't access another role's shell.

## 2. Business logic
Redirect rules (extend EPIC-01 T-012's redirect):
- Unauthenticated → `/auth/phone`.
- Authenticated, no role → `/role`.
- Authenticated, role set → that role's shell home (`/landlord/home` | `/manager/home` | `/tenant/home`).
- Authenticated user trying to enter a different role's shell → bounce to own shell home.
- Logout → `/auth/phone`.
This closes the EPIC-01 `// TODO(EPIC-02) role routing` seam.

## 3. What this task DOES
- Update `app_router.dart` redirect to implement the full table (reads `authStateProvider` role).
- Remove the EPIC-01 `/home` placeholder route + screen.
- Splash → after bootstrap, route per the table.
- Tests: each redirect branch incl. wrong-role bounce.

## 4. What this task does NOT do
- No new screens.

## 5. Files & changes
### Add
- `test/role_redirect_test.dart`
### Update
- `lib/core/router/app_router.dart` — full redirect table; remove `/home`
- remove `lib/features/home_placeholder/...` (EPIC-01 temp)
### Delete
- EPIC-01 `/home` placeholder screen + route

## 6. Database changes
No DB changes.

## 7. API changes
No API changes (reads role from auth state / me).

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- No new screen; routing behavior only
- Navigation: the redirect table above
- States: splash loading during bootstrap, then redirect

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] Redirect: unauth→phone; auth+norole→/role; auth+role→shell home
- [x] Wrong-role shell access → bounce to own shell
- [x] EPIC-01 /home placeholder removed
- [x] Splash routes per table after bootstrap
- [x] Tests: each branch + wrong-role bounce (role_redirect_test.dart)
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this env

## 12. Test plan
### Automated
- role_redirect_test → unauth→phone; norole→/role; landlord→/landlord/home; landlord visiting /manager/* → bounced to /landlord/home
### Manual QA
1. Full path: new user → OTP → chooser → shell. Returning landlord → straight to landlord shell. Manually navigate to /tenant/home as landlord → bounced.

## 13. Acceptance criteria
- [x] Redirect table fully enforced incl. wrong-role bounce.
- [x] EPIC-01 /home seam replaced; no dead placeholder.
- [x] Full onboarding→role→shell flow works end-to-end (code complete; OTP success
      now bounces through splash → redirect resolves role/shell).
- [ ] Test + analyze pass — BLOCKED: no Flutter/Dart toolchain in this env.

## 14. Self-review
- [x] Guards read DB-truth role (via auth state, seeded from `/auth/me`)
- [x] No redirect loops (`/role` reachable when authenticated; splash/auth/onboarding
      resolve to a single destination per pass; wrong-shell bounce targets own home)
- [x] EPIC-01 seam fully removed (route + screen deleted; OTP `successRoutePath`
      no longer points at `/home`)
### Deviations from spec
- analyze + test could not be executed here (no Flutter/Dart toolchain) — same
  environment blocker as EPIC-02/T-003, T-004, T-005. Tests are written and
  reviewed for correctness but not run green in this env.
- OTP `successRoutePath` was repointed from the deleted `/home` to the splash
  route (`/`); the T-008 redirect, driven by AuthState, then resolves the real
  destination (`/role` or the role shell). This keeps the post-verify transition
  immediate without the screen needing to know the role.
- EPIC-01 `router_redirect_test.dart` and `theme_i18n_test.dart` referenced the
  deleted `HomePlaceholderScreen`; both were updated to assert on the landlord
  shell instead (in scope: removing the EPIC-01 seam).
- The unused l10n key `home_placeholder_welcome` was left in the ARB/generated
  files to avoid l10n codegen drift (no toolchain to regenerate).
### Files touched (actual)
- lib/core/router/app_router.dart (update: full role redirect table; remove /home route + import; add _shellHomeFor/_shellPrefixFor helpers)
- lib/features/home_placeholder/... (delete: EPIC-01 placeholder screen)
- lib/features/auth/presentation/screens/otp_entry_screen.dart (update: successRoutePath → splash; let redirect resolve)
- test/role_redirect_test.dart (add: each branch + wrong-role bounce + /role re-entry)
- test/router_redirect_test.dart (update: drop /home; assert landlord shell)
- test/theme_i18n_test.dart (update: assert landlord shell + nav_home copy)

## 15. Notes for the implementing agent
- This is the EPIC-02 validation gate: when it passes, role selection + the three shells + guards all work end-to-end.
- Guard against loops: a user with role but on `/role` should be allowed to re-choose (switch role), so don't force-redirect away from `/role` when it's reached intentionally from More. Use a query flag or allow `/role` when authenticated.
