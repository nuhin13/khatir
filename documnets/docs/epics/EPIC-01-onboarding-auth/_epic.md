# EPIC-01 · Onboarding & Authentication

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-00
**Tasks:** 12 · **External services:** WhatsApp Business API (OTP delivery — stub/console in dev until approved); SMS gateway (fallback)

---

## Business goal

Let a brand-new user open the app, understand what Khatir is through three intro slides, and create an account using only their phone number and a one-time code (OTP). No passwords. This is the front door — everything authenticated depends on it.

## User-visible outcome

A first-time user sees 3 intro slides (Bangla by default), enters their phone number, receives a 6-digit code (via WhatsApp, SMS fallback), enters it, and lands authenticated in the app. Returning users skip onboarding and log in straight away. Tokens persist so they stay logged in across app restarts.

## Scope

**In scope**
- 3 onboarding/intro slides (skippable, re-viewable later).
- Phone-number entry with BD format validation.
- OTP request + verify endpoints; OTP stored in Redis (hashed, short TTL, attempt-limited).
- Dev mode: OTP printed to console/logs so the app is buildable before WhatsApp approval.
- WhatsApp send integration (behind an interface) + SMS fallback.
- JWT access + refresh issuance; secure token storage on device; dio interceptor that attaches the token and refreshes on 401.
- Logout.
- Rate limiting on OTP request/verify.

**Out of scope**
- Role selection and role shells (EPIC-02).
- Profile editing beyond what signup needs (EPIC-02).
- Real WhatsApp Business API approval (operational task, runs in parallel; dev uses console/stub).
- Admin auth (EPIC-11, separate `AdminUser`).

## Dependencies

- **Prerequisite epic:** EPIC-00 (needs the Django `core` app, the `User`-less scaffold, dio client, router, theme + i18n, secure storage).
- **External:** WhatsApp Business API (stubbed in dev), SMS gateway (stubbed in dev). Neither blocks building — both sit behind a `NotificationSender` interface with a console implementation for dev.
- **Design:** intro slides + phone/OTP screens reference `ui/KhatirMobile.jsx` and the Notun Din theme.

## Data-model changes

- **New `accounts` app** with the `User` model (custom user, phone is the identity) — see `06_database_schema.md` Domain 1.
- OTP is **not** a DB table — it lives in Redis (`otp:{phone}`).
- This epic introduces the custom `AUTH_USER_MODEL`; it must be set before the first `accounts` migration (critical Django constraint — see T-002 of this epic).

## API surface

- `POST /api/v1/auth/request-otp` — send a code to a phone.
- `POST /api/v1/auth/verify-otp` — verify code, return JWT pair + user.
- `POST /api/v1/auth/refresh` — exchange refresh for new access.
- `POST /api/v1/auth/logout` — invalidate refresh (blacklist).
- `GET /api/v1/auth/me` — current user (used by the app to bootstrap session).

## UI screens (Flutter)

- Onboarding slides (`/onboarding`).
- Phone entry (`/auth/phone`).
- OTP entry (`/auth/otp`).
- Splash (`/`) decides: onboarding (first launch) → auth → (role check happens in EPIC-02).

## Feature flags introduced

None. (Channel selection — WhatsApp vs SMS — is config, read from `SystemConfig`, not a feature flag.)

## Admin-portal config keys (seeded into SystemConfig)

- `otp_length` (int, default 6)
- `otp_ttl_seconds` (int, default 300)
- `otp_max_attempts` (int, default 5)
- `otp_resend_cooldown_seconds` (int, default 60)
- `auth_primary_channel` (text, default `whatsapp`)
- `intro_slide_skip_allowed` (bool, default true)

## Test strategy

- Backend: OTP request/verify happy paths; wrong code; expired code; too many attempts; resend cooldown; refresh; logout/blacklist; rate-limit. JWT contains expected claims. `me` returns the user.
- Mobile: widget tests for the three screens; provider/controller unit tests for the auth flow (request → verify → token stored); interceptor refresh logic.

## Acceptance criteria (epic-level)

- [ ] First-time user: onboarding → phone → OTP → authenticated session.
- [ ] OTP is 6-digit, hashed in Redis, expires per config, attempt-limited, resend-cooldown enforced.
- [ ] Dev mode logs the OTP (no real send needed to build/test).
- [ ] WhatsApp + SMS senders behind one interface; console sender used in dev.
- [ ] JWT access+refresh issued; refresh works; logout blacklists refresh.
- [ ] Tokens stored securely on device; session survives app restart; 401 triggers refresh, refresh-fail routes to phone entry.
- [ ] All config values come from `SystemConfig`, not hardcoded.
- [ ] `make test` + `make lint` pass for api + mobile.

## Task list

| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Seed auth SystemConfig keys | backend | XS | EPIC-00.T-005 |
| T-002 | `accounts` app + custom User model | backend | M | EPIC-00.T-005 |
| T-003 | OTP store (Redis) + generation/verification service | backend | M | T-002, T-001 |
| T-004 | NotificationSender interface + console/WhatsApp/SMS impls | backend | M | T-003 |
| T-005 | Auth endpoints: request-otp / verify-otp | backend | M | T-003, T-004 |
| T-006 | JWT issue/refresh/logout + `me` endpoint | backend | M | T-005 |
| T-007 | Rate limiting on auth endpoints | backend | S | T-005 |
| T-008 | Flutter onboarding slides | mobile | M | EPIC-00.T-008 |
| T-009 | Flutter phone-entry screen | mobile | M | T-008 |
| T-010 | Flutter OTP-entry screen | mobile | M | T-009 |
| T-011 | Flutter auth state + token storage + dio refresh interceptor | mobile | M | T-006, T-010 |
| T-012 | Splash routing + session bootstrap + logout wiring | mobile | S | T-011 |

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| WhatsApp API not approved yet | Sender interface + console impl; build/test fully without it; swap impl when approved |
| Setting custom User model late breaks migrations | T-002 sets `AUTH_USER_MODEL` and creates the first migration *before* any other app migrates; documented as a hard ordering rule |
| OTP brute force | Hashed codes, short TTL, attempt cap, resend cooldown, endpoint rate limiting (T-007) |
| SMS/WhatsApp cost abuse | Rate limit per phone + per IP; cooldown; monitor in observability |
| Token theft | Short access lifetime + refresh rotation + secure storage; logout blacklists |
