---
id: T-003
epic: EPIC-11
title: Admin auth endpoints (login, MFA, logout, me)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-007]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Admin auth endpoints (login, MFA, logout, me)

## 1. Feature goal
Secure admin login: email+password → MFA challenge → session token. Separate JWT signing key from customer auth.

## 2. Business logic
POST /login: verify password → if MFA required (from config), return `mfa_required` challenge. POST /verify-mfa: verify TOTP code → issue admin JWT (separate signing key, short TTL). Logout invalidates. Disabled accounts blocked. Audit on login/logout/failed MFA. Session timeout from config.

## 3. What this task DOES
- Login/MFA/logout/me endpoints; separate JWT key; rate-limiting; audit; tests.

## 5. Files & changes
### Add
- admin_portal/{serializers,services,views,urls}.py; tests/test_admin_auth.py
### Update
- config/urls.py (admin prefix)

## 6. Database changes
No schema change.
## 7. API changes
| POST | /admin/api/auth/login | public | 200 (token or mfa_challenge) |
| POST | /admin/api/auth/verify-mfa | public | 200 (admin JWT) |
| POST | /admin/api/auth/logout | admin | 204 |
| GET  | /admin/api/auth/me | admin | 200 |

## 8. UI changes
No UI (T-007 builds it).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] login (verify password, return mfa_challenge or token)
- [x] verify-mfa (TOTP, issue admin JWT with separate key)
- [x] logout (blacklist/invalidate)
- [x] me endpoint
- [x] disabled accounts blocked
- [x] admin_mfa_required config respected
- [x] rate-limit on login + verify-mfa
- [x] audit on login/logout/failed
- [x] Tests: happy login, wrong password, MFA wrong, disabled, rate-limit
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_login_success, test_wrong_password, test_mfa_wrong, test_disabled, test_rate_limit
### Manual QA
1. Full admin login → MFA → dashboard.

## 13. Acceptance criteria
- [x] Admin auth flow complete + audited; separate JWT; tests + lint pass.
## 14. Self-review
- [x] ADMIN_JWT_SIGNING_KEY separate from JWT_SIGNING_KEY; TOTP verified correctly
### Deviations from spec
- Admin tokens are minted with **PyJWT directly** (HS256) rather than via
  ``rest_framework_simplejwt``, because ``AdminUser`` is not a Django auth user
  (T-001) and simplejwt binds tokens to ``AUTH_USER_MODEL``. A self-contained
  token + a dedicated ``AdminJWTAuthentication`` keeps the two realms fully
  separate. Logout revokes by ``jti`` in the cache (no DB blacklist table).
- ``verify-mfa`` is rate-limited by IP only (it carries an opaque ``mfa_token``,
  no email); the per-email login throttle already caps challenge issuance.
- Config (``ADMIN_MFA_REQUIRED``, ``ADMIN_SESSION_TIMEOUT_MINUTES``, lifetimes,
  throttle rates) lives in settings/env — there is no admin SystemConfig surface yet.
### Files touched (actual)
- Add: admin_portal/{auth_tokens,authentication,services,serializers,throttling,
  urls,views}.py; admin_portal/tests/test_admin_auth.py
- Update: config/urls.py (admin auth prefix), config/settings/base.py
  (ADMIN_JWT_* + ADMIN_MFA_* + admin throttle rates), pyproject.toml/uv.lock (pyotp)

## 15. Notes for the implementing agent
- Use `pyotp` for TOTP. ADMIN_JWT_SIGNING_KEY from env. Short access TTL (e.g. 60 min, from config). Session timeout = config admin_session_timeout_minutes.
