---
id: T-010
epic: EPIC-01
title: Flutter OTP-entry screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-009]
blocks: [T-011]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Flutter OTP-entry screen

## 1. Feature goal
Let the user enter the 6-digit code, verify it via `verify-otp`, and on success hand the returned tokens + user to the auth state layer (T-011). Includes resend with cooldown.

## 2. Business logic
- 6-box OTP input; auto-advance; auto-submit when full.
- Call `POST /auth/verify-otp`; on success pass `{access, refresh, user}` to the auth controller (T-011) which stores tokens and routes onward.
- Resend button disabled during cooldown (countdown from `otp_resend_cooldown_seconds`), re-calls request-otp.
- Errors: wrong/expired code (inline, clear input), rate-limited, network.

## 3. What this task DOES
- Repository `verifyOtp(phone, code)` + `resendOtp(phone)`.
- `verify_otp_controller` (AsyncNotifier).
- `otp_entry_screen.dart`: 6-box input, resend w/ countdown, loading/error states.
- On success, call into the auth state layer (T-011) — until T-011 lands, store tokens via a temporary hook and route to a placeholder; T-011 replaces this.
- Route `/auth/otp` (receives phone arg).
- Widget test: full code triggers verify; wrong code shows error; resend disabled during cooldown.

## 4. What this task does NOT do
- Does not own token persistence / interceptor (T-011) — it calls into it.
- No role routing (EPIC-02).

## 5. Files & changes
### Add
- `lib/features/auth/presentation/screens/otp_entry_screen.dart`
- `lib/features/auth/presentation/controllers/verify_otp_controller.dart`
- `lib/features/auth/presentation/widgets/otp_input.dart`, `resend_button.dart`
- ARB keys
- `test/otp_entry_screen_test.dart`
### Update
- `auth_repository.dart` (verifyOtp, resendOtp)
- `lib/core/router/app_router.dart` — `/auth/otp`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `POST /auth/verify-otp` + `POST /auth/request-otp` (resend).

## 8. UI changes
- **Design source:** screen `otp` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-onboard.js` → `reg('otp')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Screen/route: `/auth/otp` (phone arg)
- Translate layout + composition + copy; values from `packages/design-tokens`
- States: data, loading (verifying), error (wrong/expired/rate-limited/network), resend-cooldown
- Navigation: success → (T-011 decides: session set → splash/role); placeholder until T-011
- i18n keys: `auth_otp_title`, `auth_otp_sent_to`, `auth_otp_invalid`, `auth_otp_expired`, `auth_otp_resend`, `auth_otp_resend_in` (bn + en) — lift copy from the `otp` screen

## 9. External services
None directly.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] verifyOtp + resendOtp repository methods
- [x] verify_otp_controller (AsyncNotifier)
- [x] 6-box OTP input, auto-advance + auto-submit
- [x] resend button w/ cooldown countdown
- [x] loading + error states (wrong/expired/429/network)
- [x] success hands tokens+user to auth layer (temp hook until T-011)
- [x] route /auth/otp with phone arg
- [x] ARB bn + en
- [x] Widget test: verify path, error, resend cooldown
- [x] analyze + test pass; no inline strings/colors

## 12. Test plan
### Automated
- otp_entry_screen_test → full code calls verify; wrong code shows error; resend disabled mid-cooldown
### Manual QA
1. Enter code from dev logs → success.
2. Wrong code → error; resend after cooldown works.

## 13. Acceptance criteria
- [ ] Correct code verifies and yields tokens+user to the auth layer.
- [ ] Resend respects cooldown.
- [ ] All error states handled.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Tokens not persisted here directly beyond the T-011 handoff
- [ ] States complete; strings/colors from ARB/theme
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Until T-011 is merged, you may temporarily store tokens via secure storage to unblock manual testing, but clearly mark that hook `// TODO(T-011) replace` so T-011 owns it. Don't duplicate interceptor logic here.
- Cooldown countdown driven by a simple timer provider; reset on successful resend.
