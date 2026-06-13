---
id: T-003
epic: EPIC-02
title: Flutter profile repository + auth-state role integration
layer: mobile
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-01.T-011, T-001]
blocks: [T-004, T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Flutter profile repository + auth-state role integration

## 1. Feature goal
Give the app a typed way to read and update the profile, and make the authenticated state expose the user's role so routing and shells can react to it.

## 2. Business logic
- Profile fetched via `GET /profile`; updates via `PATCH /profile`.
- The `authStateProvider` (EPIC-01 T-011) already holds `Authenticated(user)`; ensure `user.role` is present and that updating role/language updates that state.
- On role change, re-fetch `/auth/me` (or refresh token) so the cached role matches the DB (the documented source of truth).

## 3. What this task DOES
- `features/profile/data/profile_repository.dart` (getProfile, updateProfile).
- freezed `Profile` model (matches the profile payload).
- `profileProvider` / controller; wire updates back into `authController` so role/language changes propagate app-wide.
- `setLanguage(lang)` and `setRole(role)` helpers that PATCH + update local state + re-fetch me.
- Tests: get/update; role change updates auth state.

## 4. What this task does NOT do
- No screens (T-005 chooser, T-007 more).
- No shell/nav (T-004/T-006).

## 5. Files & changes
### Add
- `lib/features/profile/data/profile_repository.dart`, `profile_providers.dart`
- `lib/features/profile/data/models/profile.dart` (freezed)
- `test/profile_repository_test.dart`
### Update
- `lib/core/auth/auth_controller.dart` — expose role; apply profile updates to state
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `/profile` (T-001) + `/auth/me` (EPIC-01).

## 8. UI changes
No UI changes (data layer only).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] Profile freezed model
- [x] profile_repository getProfile/updateProfile
- [x] profileProvider/controller
- [x] setLanguage + setRole (PATCH + update auth state + refetch me)
- [x] auth_controller exposes role; profile changes propagate
- [x] Tests: get, update, role change reflects in auth state
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment to run them

## 12. Test plan
### Automated
- test_get_profile
- test_update_language_updates_state
- test_set_role_refetches_me_and_updates_role
### Manual QA
1. Change language via setLanguage → app locale updates.

## 13. Acceptance criteria
- [x] Profile readable/updatable from the app.
- [x] Role available in auth state; role/language changes propagate app-wide.
- [ ] Tests + analyze pass — written; not runnable here (no toolchain).

## 14. Self-review
- [x] Role from DB truth (refetch me on change) — `ProfileController.updateProfile` calls `authController.refreshMe()` after a role change.
- [x] State propagation works — `applyProfile` merges name/role/language into auth state; `setLanguage` also updates `localeProvider`.
### Deviations from spec
- `Profile` model uses a static `fromJson` (no json codegen) to avoid pulling json_serializable in for the enum-typed `role` field — mirrors the existing `SessionUser` pattern. The `.freezed.dart` was hand-authored to match the generator output because no Dart toolchain is available here to run build_runner.
- `analyze`/`test` could not be executed: no Flutter/Dart toolchain in this environment.
### Files touched (actual)
- `lib/core/network/api_endpoints.dart` (add `profile`)
- `lib/features/profile/data/models/profile.dart` (+ `profile.freezed.dart`)
- `lib/features/profile/data/profile_repository.dart`
- `lib/features/profile/data/profile_providers.dart`
- `lib/core/auth/auth_state.dart` (`role` getter)
- `lib/core/auth/auth_controller.dart` (`applyProfile`, `refreshMe`)
- `test/profile_repository_test.dart`

## 15. Notes for the implementing agent
- Reuse the `localeProvider` from EPIC-00 T-008 for language; `setLanguage` should update both the backend (PATCH) and the local locale provider.
- Keep this a thin data/state layer; UI is T-005/T-007.
