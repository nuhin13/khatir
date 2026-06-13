---
id: T-009
epic: EPIC-01
title: Flutter phone-entry screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-008]
blocks: [T-010]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Flutter phone-entry screen

## 1. Feature goal
Let the user enter their phone number, validate it (BD format), call `request-otp`, and navigate to the OTP screen on success.

## 2. Business logic
- BD phone input with `+880` handling; validate before enabling submit.
- On submit → call `POST /auth/request-otp`; on success route to `/auth/otp` passing the phone (typed args).
- Handle errors: invalid phone (inline), rate-limited 429 (friendly "try later"), network error (retry).
- Show loading on the button while the request is in flight.

## 3. What this task DOES
- `features/auth/` repository method `requestOtp(phone)` (dio).
- Riverpod controller (AsyncNotifier) for the request action.
- `phone_entry_screen.dart` with a phone field (KTextField), submit (KButton), inline validation, loading/error states.
- Route `/auth/phone` → on success `/auth/otp` with phone arg.
- Widget test: invalid phone disables submit; valid triggers controller.

## 4. What this task does NOT do
- No OTP verification (T-010).

## 5. Files & changes
### Add
- `lib/features/auth/data/auth_repository.dart` (requestOtp) + `auth_providers.dart`
- `lib/features/auth/data/models/` (request/response freezed models)
- `lib/features/auth/presentation/screens/phone_entry_screen.dart`
- `lib/features/auth/presentation/controllers/request_otp_controller.dart`
- `lib/core/router/args/auth_args.dart` (typed route args)
- ARB keys
- `test/phone_entry_screen_test.dart`
### Update
- `lib/core/router/app_router.dart` — `/auth/phone`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `POST /api/v1/auth/request-otp` (exists from T-005).

## 8. UI changes
- **Design source:** screen `login` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-onboard.js` → `reg('login')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Screen/route: `/auth/phone`
- Translate layout + composition + copy; values from `packages/design-tokens`
- States: data, loading (submitting), error (invalid/rate-limited/network)
- Navigation: success → `/auth/otp` with phone
- i18n keys: `auth_phone_title`, `auth_phone_hint`, `auth_phone_invalid`, `auth_phone_submit`, `auth_rate_limited`, `common_network_error` (bn + en) — lift copy from the `login` screen

## 9. External services
None directly (backend handles sending).

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] auth_repository.requestOtp via dio
- [ ] freezed request/response models
- [ ] request_otp_controller (AsyncNotifier)
- [ ] phone_entry_screen with field + submit + validation
- [ ] loading + error states (invalid / 429 / network)
- [ ] route /auth/phone → /auth/otp with typed phone arg
- [ ] ARB strings bn + en
- [ ] Widget test: validation + submit path
- [ ] analyze + test pass; no inline strings/colors

## 12. Test plan
### Automated
- phone_entry_screen_test → invalid phone keeps submit disabled; valid calls controller; error shows message
### Manual QA
1. Enter a valid BD number → OTP screen; backend (dev) logs code.
2. Trigger 429 → friendly message.

## 13. Acceptance criteria
- [ ] Valid phone → request-otp → OTP screen.
- [ ] Errors handled (invalid, rate-limited, network).
- [ ] Loading state on submit.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Typed route args (no loose maps)
- [ ] All four states present
- [ ] Strings/colors from ARB/theme
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Normalize to E.164 before sending (`01XXXXXXXXX` → `+8801XXXXXXXXX`).
- Keep the phone arg passed via go_router `extra` as a typed `AuthArgs`, not a raw string map.
