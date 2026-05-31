---
id: T-007
epic: EPIC-00
title: Flutter app scaffold (structure, router skeleton)
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-008, T-011, T-013, T-014, T-015]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Flutter app scaffold (structure, router skeleton)

## 1. Feature goal
Create the Flutter app at `apps/mobile/` with the folder-by-feature structure, core plumbing (dio client, secure storage, go_router skeleton, Riverpod ProviderScope), and a placeholder screen that boots on Android + iOS.

## 2. Business logic
Follows `02_project_structure.md` (Flutter layout) and `01_stack_and_standards.md` (Riverpod, go_router, dio, freezed). No features yet — structure + a routable placeholder.

## 3. What this task DOES
- `flutter create` at `apps/mobile/` (latest stable Flutter), org `bd.com.khatir`.
- Add deps: go_router, hooks_riverpod, dio, freezed, json_serializable, flutter_secure_storage, intl, build_runner, flutter_lints.
- `lib/main.dart` (ProviderScope), `lib/app.dart` (MaterialApp.router).
- `lib/core/router/app_router.dart` with routes: `/` splash → `/placeholder`.
- `lib/core/network/dio_client.dart` (single dio provider + auth/error interceptor stubs, base URL from `--dart-define`).
- `lib/core/storage/secure_storage.dart` (token read/write wrapper).
- `lib/core/enums/` (Role enum stub matching enums.md).
- `analysis_options.yaml` (flutter_lints + 100 col).
- Flavors: dev/staging/prod (Android flavors + iOS schemes) reading `API_BASE_URL`, `APP_ENV` from `--dart-define`.
- A placeholder screen + one widget test.

## 4. What this task does NOT do
- No theme tokens / i18n yet (T-008).
- No real screens, no auth.

## 5. Files & changes
### Add
- `apps/mobile/` full Flutter project
- `lib/main.dart`, `lib/app.dart`
- `lib/core/router/app_router.dart`
- `lib/core/network/dio_client.dart`, `api_endpoints.dart`, `api_exception.dart`
- `lib/core/storage/secure_storage.dart`
- `lib/core/enums/role.dart`
- `lib/features/placeholder/presentation/screens/placeholder_screen.dart`
- `test/placeholder_screen_test.dart`
- `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock`
### Update
- none
### Delete
- default `flutter create` counter sample (`test/widget_test.dart`, sample home)

## 6. Database changes
No DB changes.

## 7. API changes
No API changes (dio points at `API_BASE_URL` for later use).

## 8. UI changes
- Surface: mobile
- Screen: `/placeholder` — shows "Khatir" + a value read from `--dart-define APP_ENV`
- States: data only (placeholder); real state patterns start in features
- Navigation: `/` splash → `/placeholder`

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] flutter create, org bd.com.khatir, latest stable
- [ ] deps added (go_router, riverpod, dio, freezed, secure_storage, intl, build_runner, flutter_lints)
- [ ] main.dart ProviderScope + app.dart MaterialApp.router
- [ ] app_router.dart with splash → placeholder
- [ ] dio_client provider + interceptor stubs, base URL from dart-define
- [ ] secure_storage wrapper
- [ ] Role enum stub
- [ ] flavors dev/staging/prod
- [ ] placeholder screen + widget test
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] builds on Android (iOS if macOS available)

## 12. Test plan
### Automated
- placeholder_screen_test → renders "Khatir" text
### Manual QA
1. `flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=APP_ENV=dev` boots to placeholder.

## 13. Acceptance criteria
- [ ] App builds + runs to placeholder on Android.
- [ ] go_router + Riverpod + dio wired.
- [ ] analyze + test pass.

## 14. Self-review
- [ ] Folder-by-feature structure matches architecture 02
- [ ] No inline strings/colors (placeholder is minimal)
- [ ] dart-define used for config (no secrets in binary)
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- iOS build requires macOS; if not available, verify Android and note iOS as pending in self-review (acceptable for this task).
- Do not bake any secret into the app; only `API_BASE_URL` + `APP_ENV` via dart-define.
- Keep interceptors as stubs; real auth attach/refresh lands in EPIC-01.
