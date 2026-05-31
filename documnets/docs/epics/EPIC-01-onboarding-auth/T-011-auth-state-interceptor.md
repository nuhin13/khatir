---
id: T-011
epic: EPIC-01
title: Flutter auth state + token storage + dio refresh interceptor
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-006, T-010]
blocks: [T-012]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-011 · Flutter auth state + token storage + dio refresh interceptor

## 1. Feature goal
Own the app's authentication state: persist tokens securely, expose an auth state provider the whole app reads, attach the access token to requests, and transparently refresh on 401 (routing to phone entry if refresh fails).

## 2. Business logic
- Tokens stored in `flutter_secure_storage`.
- A single `authStateProvider` exposes `Unauthenticated | Authenticated(user)` and is the source of truth for routing (consumed by splash/redirect in T-012 and role shells in EPIC-02).
- dio request interceptor attaches `Authorization: Bearer <access>`.
- dio error interceptor: on 401, attempt `POST /auth/refresh` once; on success retry the original request; on failure clear tokens → set Unauthenticated (router redirects to `/auth/phone`).
- `setSession(tokens, user)` (called by T-010 verify success) and `logout()` (clears storage + calls `/auth/logout`).

## 3. What this task DOES
- `core/auth/auth_state.dart` (freezed state) + `auth_controller.dart` (Riverpod) with `setSession`, `logout`, `bootstrap` (load tokens + call `/auth/me`).
- `core/auth/token_storage.dart` (secure storage wrapper — finalize the EPIC-00 stub).
- Upgrade `dio_client.dart` interceptors (attach token, refresh-on-401-with-retry).
- Replace the temporary hook from T-010 so verify-success calls `authController.setSession`.
- Tests: token persisted; bootstrap loads session; 401 triggers refresh; refresh-fail logs out.

## 4. What this task does NOT do
- No role-based routing yet (EPIC-02) — it only sets Authenticated/Unauthenticated. T-012 wires splash; EPIC-02 adds role shells.

## 5. Files & changes
### Add
- `lib/core/auth/auth_state.dart`, `auth_controller.dart`, `token_storage.dart`
- `test/auth_controller_test.dart`, `test/dio_refresh_test.dart`
### Update
- `lib/core/network/dio_client.dart` (interceptors)
- `lib/features/auth/.../verify_otp_controller.dart` (call setSession; remove T-010 temp hook)
### Delete
- T-010 temporary token hook

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `/auth/refresh`, `/auth/me`, `/auth/logout` (from T-006).

## 8. UI changes
No new screen; provides the auth state the router consumes. (Splash wiring is T-012.)

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] token_storage secure wrapper (read/write/clear)
- [ ] auth_state (freezed) + auth_controller (setSession/logout/bootstrap)
- [ ] dio request interceptor attaches access token
- [ ] dio error interceptor: 401 → refresh once → retry; fail → logout
- [ ] verify-success calls setSession (T-010 temp hook removed)
- [ ] bootstrap: load tokens + /auth/me → Authenticated/Unauthenticated
- [ ] Tests: persist, bootstrap, refresh-on-401, refresh-fail logout
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_set_session_persists
- test_bootstrap_loads_user
- test_401_triggers_refresh_and_retry
- test_refresh_failure_logs_out
### Manual QA
1. Log in → kill app → reopen → still authenticated (bootstrap + /me).
2. Force access expiry → next call refreshes silently.
3. Invalidate refresh → app logs out to phone screen.

## 13. Acceptance criteria
- [ ] Session persists across restarts.
- [ ] 401 auto-refreshes + retries once.
- [ ] Refresh failure clears session → Unauthenticated.
- [ ] Tests + analyze pass.

## 14. Self-review
- [ ] Single source of truth for auth state
- [ ] Refresh attempted once (no infinite loop)
- [ ] Tokens only in secure storage; never logged
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Guard against refresh loops: if the refresh call itself 401s, do not recurse — clear + logout.
- Keep a single in-flight refresh (mutex) so concurrent 401s don't fire multiple refreshes.
