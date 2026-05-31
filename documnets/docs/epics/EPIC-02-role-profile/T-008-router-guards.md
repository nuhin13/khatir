---
id: T-008
epic: EPIC-02
title: Router role-redirect guards + replace EPIC-01 /home seam
layer: mobile
size: S
status: todo
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
- [ ] Redirect: unauth→phone; auth+norole→/role; auth+role→shell home
- [ ] Wrong-role shell access → bounce to own shell
- [ ] EPIC-01 /home placeholder removed
- [ ] Splash routes per table after bootstrap
- [ ] Tests: each branch + wrong-role bounce
- [ ] analyze + test pass

## 12. Test plan
### Automated
- role_redirect_test → unauth→phone; norole→/role; landlord→/landlord/home; landlord visiting /manager/* → bounced to /landlord/home
### Manual QA
1. Full path: new user → OTP → chooser → shell. Returning landlord → straight to landlord shell. Manually navigate to /tenant/home as landlord → bounced.

## 13. Acceptance criteria
- [ ] Redirect table fully enforced incl. wrong-role bounce.
- [ ] EPIC-01 /home seam replaced; no dead placeholder.
- [ ] Full onboarding→role→shell flow works end-to-end.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Guards read DB-truth role (via auth state)
- [ ] No redirect loops
- [ ] EPIC-01 seam fully removed
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This is the EPIC-02 validation gate: when it passes, role selection + the three shells + guards all work end-to-end.
- Guard against loops: a user with role but on `/role` should be allowed to re-choose (switch role), so don't force-redirect away from `/role` when it's reached intentionally from More. Use a query flag or allow `/role` when authenticated.
