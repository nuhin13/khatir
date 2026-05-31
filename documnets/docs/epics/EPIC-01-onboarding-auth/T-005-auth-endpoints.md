---
id: T-005
epic: EPIC-01
title: Auth endpoints — request-otp / verify-otp
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-006, T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Auth endpoints — request-otp / verify-otp

## 1. Feature goal
Expose the two public endpoints that drive sign-in: request an OTP for a phone number, and verify the OTP. On successful verify, create-or-fetch the `User` and hand off to JWT issuance (T-006).

## 2. Business logic
- `request-otp`: validate BD phone (E.164), check resend cooldown, generate OTP (T-003), dispatch via sender (T-004). In dev, also log the code.
- `verify-otp`: validate code via T-003; on success, get-or-create the `User` by phone (new users get default role, set properly in EPIC-02); return a marker that T-006 turns into JWTs. (T-005 and T-006 may be one PR; keep endpoints thin.)
- Errors use the standard envelope codes: `validation_error`, `rate_limited`, `auth_invalid` (wrong/expired code).
- Logic in `services.py`; views thin.

## 3. What this task DOES
- `accounts/serializers.py`: RequestOtpSerializer (phone), VerifyOtpSerializer (phone, code).
- `accounts/services.py`: `request_otp(phone)`, `verify_otp_and_get_user(phone, code) -> User`.
- `accounts/views.py`: two APIViews; `accounts/urls.py` under `/api/v1/auth/`.
- Phone validation (E.164, BD `+8801…`).
- Dev-only: log the OTP code at INFO (guarded by `DJANGO_ENV=dev`).
- Tests: happy request, invalid phone, cooldown; happy verify (creates user), wrong code, expired.

## 4. What this task does NOT do
- Does not issue JWTs yet (T-006 — but they're tightly coupled; can ship together).
- No rate limiting yet (T-007).

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/serializers.py`
- `apps/api/khatir/accounts/views.py`
- `apps/api/khatir/accounts/urls.py`
- `apps/api/khatir/accounts/tests/test_auth_endpoints.py`
### Update
- `config/urls.py` — include `accounts.urls` under `/api/v1/auth/`
- `accounts/services.py` — add request/verify services
### Delete
- none

## 6. Database changes
- May create a `User` row on first successful verify (get_or_create). No schema change.

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | /api/v1/auth/request-otp | none | {phone} | {sent:true, channel, cooldown} | 200 |
| POST | /api/v1/auth/verify-otp | none | {phone, code} | {access, refresh, user} (JWT from T-006) | 200 |

(Verify response's tokens are added in T-006; until then return the authenticated user + a placeholder, or land T-005+T-006 together.)

## 8. UI changes
No UI changes (consumed by mobile T-009/T-010).

## 9. External services
Via T-004 senders. Dev = console.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] Serializers (request, verify) with E.164 BD phone validation
- [ ] request_otp service: cooldown + generate + dispatch
- [ ] verify_otp_and_get_user service: verify + get_or_create user
- [ ] Two thin APIViews + urls under /api/v1/auth
- [ ] Dev-only OTP logging (guarded)
- [ ] Error envelope codes correct (validation/rate_limited/auth_invalid)
- [ ] Tests: request happy/invalid-phone/cooldown; verify happy/wrong/expired
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_request_otp_success / invalid_phone / cooldown
- test_verify_success_creates_user / wrong_code / expired_code
### Manual QA
1. POST request-otp (dev) → code in logs.
2. POST verify-otp with that code → user created/returned.

## 13. Acceptance criteria
- [ ] Both endpoints work end-to-end in dev (console OTP).
- [ ] New phone creates a User; existing phone reuses it.
- [ ] Error envelope correct for each failure.
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Views thin; logic in services
- [ ] Plaintext OTP only logged in dev, never stored
- [ ] Phone validated E.164
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Recommended: implement T-005 and T-006 in the same branch/PR since verify-otp's response needs the JWTs. If splitting, return the user object from verify and add tokens in T-006.
- Default role for brand-new users: `landlord` (changed via role chooser in EPIC-02). Do not force role here.
