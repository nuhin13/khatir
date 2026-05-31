---
id: T-007
epic: EPIC-01
title: Rate limiting on auth endpoints
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-005]
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

# T-007 · Rate limiting on auth endpoints

## 1. Feature goal
Protect the OTP endpoints from abuse (cost + brute force) by rate-limiting `request-otp` and `verify-otp` per phone and per IP.

## 2. Business logic
- Per-phone and per-IP limits on `request-otp` (prevents SMS/WhatsApp cost bombs) and `verify-otp` (prevents code brute force, on top of the per-code attempt cap in T-003).
- Limits are config-tunable (reasonable defaults; can read from SystemConfig or DRF throttle settings).
- Exceeding returns the `rate_limited` envelope code with `429`.

## 3. What this task DOES
- DRF throttle classes (scoped) for request-otp and verify-otp, keyed by phone + IP.
- Wire throttles to the two views.
- Ensure throttle responses use the standard error envelope (`rate_limited`).
- Tests: exceeding the limit returns 429 with the right code.

## 4. What this task does NOT do
- No global API throttling (that's a later infra concern).

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/throttling.py`
- `accounts/tests/test_throttling.py`
### Update
- `accounts/views.py` (attach throttles)
- `config/settings/base.py` (throttle rates) — or SystemConfig-driven
- `core/exceptions.py` if needed so throttle exceptions map to the envelope
### Delete
- none

## 6. Database changes
No DB changes (throttle state in cache/Redis).

## 7. API changes
Adds `429 rate_limited` responses to the two auth endpoints. No new endpoints.

## 8. UI changes
No UI changes (mobile shows a friendly "try again later" on 429 — handled in T-009/T-010).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] Throttle classes keyed by phone + IP
- [ ] Attached to request-otp + verify-otp
- [ ] 429 maps to `rate_limited` envelope
- [ ] Rates configurable (settings or SystemConfig)
- [ ] Tests: exceed limit → 429 + code
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_request_otp_rate_limit → N+1th call in window → 429
- test_verify_rate_limit → too many verify attempts → 429
### Manual QA
1. Hammer request-otp → eventually 429 with envelope.

## 13. Acceptance criteria
- [ ] Both endpoints rate-limited per phone + IP.
- [ ] 429 uses the standard envelope code.
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Limits sensible + configurable
- [ ] Works with cache/Redis backend
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This complements (does not replace) the per-code attempt cap in T-003 and the resend cooldown in T-001/T-003.
- Suggested defaults: request-otp 5/hour/phone, 20/hour/IP; verify-otp 10/10min/phone. Tune later.
