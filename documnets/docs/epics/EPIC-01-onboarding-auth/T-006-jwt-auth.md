---
id: T-006
epic: EPIC-01
title: JWT issue/refresh/logout + me endpoint
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-005]
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

# T-006 · JWT issue/refresh/logout + me endpoint

## 1. Feature goal
Issue JWT access + refresh tokens on successful OTP verification, support refresh and logout (refresh blacklist), and expose `GET /auth/me` so the app can bootstrap the current session.

## 2. Business logic
- Use `djangorestframework-simplejwt`. Access lifetime + refresh lifetime from env (`JWT_ACCESS_LIFETIME_MIN`, `JWT_REFRESH_LIFETIME_DAYS`); signing key `JWT_SIGNING_KEY` (separate from Django secret).
- Token carries `user_id`, `role`. Refresh rotation + blacklist on logout.
- `me` returns the authenticated user (id, phone masked-for-logs but full in payload to the owner, role, name, language).
- Update `last_login_at` on successful verify.

## 3. What this task DOES
- Configure simplejwt (lifetimes, signing key, rotation, blacklist app + migration).
- Wire verify-otp (T-005) to return `{access, refresh, user}`.
- `POST /auth/refresh` and `POST /auth/logout` (blacklist refresh).
- `GET /auth/me` (auth required) → current user serializer.
- Update `last_login_at`.
- Tests: token issued + claims; refresh; logout invalidates; me requires auth.

## 4. What this task does NOT do
- No role chooser (EPIC-02). Token includes whatever role the user currently has.

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/auth_tokens.py` (token helpers/claims) if needed
- `UserSerializer` (in serializers.py) for `me`
- `accounts/tests/test_jwt.py`
### Update
- `config/settings/base.py` — simplejwt config, add token blacklist app
- `accounts/views.py` + `urls.py` — refresh, logout, me
- `accounts/services.py` — issue tokens after verify; update last_login_at
- migration for token blacklist app
### Delete
- none

## 6. Database changes
- simplejwt token blacklist tables (its migrations). No domain schema.

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | /api/v1/auth/verify-otp | none | {phone, code} | {access, refresh, user} | 200 |
| POST | /api/v1/auth/refresh | none | {refresh} | {access} | 200 |
| POST | /api/v1/auth/logout | Bearer | {refresh} | 204 | 204 |
| GET | /api/v1/auth/me | Bearer | — | {id, phone, role, name, language} | 200 |

## 8. UI changes
No UI changes (consumed by mobile T-011/T-012).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] simplejwt configured (lifetimes from env, separate signing key, rotation)
- [x] token blacklist app + migration
- [x] verify-otp returns access+refresh+user
- [x] /auth/refresh
- [x] /auth/logout blacklists refresh
- [x] /auth/me (auth required) + UserSerializer
- [x] last_login_at updated on verify
- [x] Tests: claims (user_id, role), refresh, logout invalidation, me auth-required
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_verify_returns_tokens + claims
- test_refresh
- test_logout_blacklists (refresh no longer works)
- test_me_requires_auth (401 without token; 200 with)
### Manual QA
1. Full loop: request → verify → use access on /me → refresh → logout → refresh fails.

## 13. Acceptance criteria
- [x] JWT pair issued with correct claims + lifetimes.
- [x] Refresh + logout (blacklist) work.
- [x] /me returns the user.
- [x] Tests + lint pass.

## 14. Self-review
- [x] Signing key separate from Django secret, from env (`JWT_SIGNING_KEY`)
- [x] Refresh rotation + blacklist on logout
- [x] No token/secret logged
### Deviations from spec
- `verify-otp` token wiring uses a new `verify_otp_and_issue_tokens` service that
  composes the existing T-005 `verify_otp_and_get_user` (kept intact) rather than
  modifying it — keeps the user-only path available and the view thin.
- Token blacklist tables come from simplejwt's own packaged migrations (applied by
  `migrate`); no hand-written migration is added (none is needed). `last_login_at`
  is stamped in the issuance service so every successful verify records it.
- `refresh` also returns a rotated `refresh` token (rotation is on) in addition to
  the spec's `{access}`; the old refresh is blacklisted after rotation.
### Files touched (actual)
- Add: `khatir/accounts/auth_tokens.py`, `khatir/accounts/tests/test_jwt.py`
- Update: `config/settings/base.py` (simplejwt config + blacklist app + DRF default
  auth), `config/settings/test.py` (deterministic >=32B signing key), `pyproject.toml`
  + `uv.lock` (add `djangorestframework-simplejwt`), `khatir/accounts/serializers.py`
  (`UserSerializer`, `RefreshSerializer`), `khatir/accounts/views.py` (refresh/logout/me
  + token-issuing verify), `khatir/accounts/urls.py` (3 routes),
  `khatir/accounts/services.py` (`verify_otp_and_issue_tokens` + `last_login_at`),
  `khatir/accounts/tests/test_auth_endpoints.py` (assert verify returns tokens)

## 15. Notes for the implementing agent
- Put `role` in the access token so clients/permissions can read it without an extra call, but treat the DB as source of truth on role change.
- Keep access lifetime short (e.g. 30 min) and refresh longer (e.g. 30 days) — values from env.
