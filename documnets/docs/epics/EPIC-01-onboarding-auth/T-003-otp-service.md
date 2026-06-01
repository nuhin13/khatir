---
id: T-003
epic: EPIC-01
title: OTP store (Redis) + generation/verification service
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, T-001]
blocks: [T-004, T-005]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · OTP store (Redis) + generation/verification service

## 1. Feature goal
Implement the OTP lifecycle in a service layer: generate a code, store it hashed in Redis with TTL + attempt tracking, and verify it — all driven by `SystemConfig` values.

## 2. Business logic
- Code length, TTL, max attempts, resend cooldown all from `SystemConfig` (T-001).
- Store **hashed** code at `otp:{phone}` (never plaintext), with `attempts` and `expires`.
- Verify: compare hash, decrement remaining attempts; exhausting attempts invalidates the code.
- Resend respects cooldown (`otp_resend_cooldown_seconds`).
- All in `accounts/services.py` (no logic in views).

## 3. What this task DOES
- `accounts/otp.py` (or within services): `generate_otp(phone)`, `verify_otp(phone, code)`, `can_resend(phone)`.
- Redis access via the configured cache/redis client.
- Codes hashed (e.g. HMAC-SHA256 with a server secret) before storing.
- Returns typed results (success / wrong / expired / too_many_attempts / cooldown) mapped to error envelope codes by the endpoint later.
- Unit tests covering every branch using a fakeredis or test Redis.

## 4. What this task does NOT do
- No endpoints (T-005), no sending (T-004), no JWT (T-006).

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/otp.py`
- `apps/api/khatir/accounts/tests/test_otp.py`
### Update
- `accounts/services.py` (expose OTP service functions) — create if not present
- `requirements`/deps: add `fakeredis` to dev/test if used
### Delete
- none

## 6. Database changes
No DB tables. OTP lives in Redis only.

## 7. API changes
No endpoints (internal service).

## 8. UI changes
No UI changes.

## 9. External services
None (Redis is infra, already present).

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] generate_otp: random N-digit per `otp_length`, hashed, stored at otp:{phone} with TTL `otp_ttl_seconds`, attempts init
- [x] verify_otp: hash-compare, decrement attempts, handle expired/too_many
- [x] can_resend: enforce `otp_resend_cooldown_seconds`
- [x] Reads all params via core.config.get_config
- [x] Codes never stored/logged in plaintext
- [x] Typed result enum for outcomes
- [x] Tests: success, wrong code, expired, too many attempts, resend cooldown
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_generate_and_verify_success
- test_wrong_code
- test_expired (advance/clear TTL)
- test_too_many_attempts (exceed max)
- test_resend_cooldown
### Manual QA
1. In a shell, generate + verify against local Redis.

## 13. Acceptance criteria
- [x] OTP generated, hashed, stored with TTL + attempts.
- [x] Verify handles all outcomes correctly.
- [x] All limits come from SystemConfig.
- [x] Tests + lint pass.

## 14. Self-review
- [x] No plaintext code in store or logs
- [x] Config-driven (no hardcoded limits)
- [x] All branches tested
### Deviations from spec
- Redis access goes through Django's cache framework (`django.core.cache.cache`,
  RedisCache in prod / LocMem in tests) — the project's established pattern
  (`core/config.py`). `fakeredis` was therefore not needed; tests run against the
  test-settings LocMem cache, so no new dev dependency was added.
- HMAC-SHA256 is keyed by `settings.SECRET_KEY` (no separate `JWT_SIGNING_KEY` is
  defined in settings yet; §15 allowed "its own" server secret).
- TTL is preserved across wrong attempts via an `expires_at` stamp in the payload
  (Django's cache exposes no portable per-key TTL read), so wrong guesses never
  extend a code's lifetime.
### Files touched (actual)
- `apps/api/khatir/accounts/otp.py` (add)
- `apps/api/khatir/accounts/services.py` (add)
- `apps/api/khatir/accounts/tests/test_otp.py` (add)

## 15. Notes for the implementing agent
- Use a server-side secret (env, e.g. derived from JWT_SIGNING_KEY or its own) for hashing so a Redis dump alone can't reveal codes.
- Dev convenience: the *endpoint* (T-005) will log the plaintext code in dev only; the *store* never holds plaintext. Keep that boundary clean.
- Prefer `fakeredis` for tests to avoid needing a live Redis in unit tests.
