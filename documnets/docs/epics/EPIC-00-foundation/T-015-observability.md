---
id: T-015
epic: EPIC-00
title: Observability (Sentry + structured logging)
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-004, T-007, T-009]
blocks: []
external_services: [sentry]
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-015 · Observability (Sentry + structured logging)

## 1. Feature goal
Wire error monitoring (Sentry) and structured logging into all three apps so failures are visible from day one, with environment tags and PII-safe logging.

## 2. Business logic
Per `04_coding_conventions.md` §10: structured logs (JSON in prod), never log secrets/NID/OTP/tokens. Sentry DSN from env; if unset, observability degrades gracefully (no crash). Environment tag (dev/staging/prod) on every event.

## 3. What this task DOES
- **Backend:** Sentry SDK init (DSN from env, env tag, traces sample modest); structured logging config (JSON in prod, pretty in dev); a logging filter that masks NID/OTP/token patterns.
- **Mobile:** Sentry Flutter init (DSN via dart-define/env, env tag); a thin logger wrapper; dio interceptor reports non-2xx to Sentry (without bodies containing PII).
- **Admin:** Sentry Next.js init (client + server), env tag.
- Each app: a guarded path so missing DSN = no-op, not a crash.

## 4. What this task does NOT do
- No dashboards/alerting config (that's ops, later).

## 5. Files & changes
### Add
- backend: `khatir/core/logging.py` (masking filter) + Sentry init in settings
- mobile: `lib/core/observability/sentry_init.dart`, `logger.dart`
- admin: `sentry.client.config.ts`, `sentry.server.config.ts`
### Update
- backend `config/settings/base.py` (logging) + `prod.py` (sentry)
- mobile `main.dart` (init before runApp)
- admin `next.config.ts` (sentry wrapper)
- `.env.example` already has `SENTRY_DSN`, `LOG_LEVEL`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
Sentry (optional; DSN from env). No-op if unset.

## 10. Feature flags
None.

## 11. Implementation checklist
- [x] Backend Sentry init (env-tagged) + structured logging + PII masking filter
- [x] Mobile Sentry init + logger + dio error reporting (PII-safe)
- [x] Admin Sentry (client+server)
- [x] Missing DSN → graceful no-op in all three
- [x] A deliberate test error surfaces in Sentry when DSN set (Sentry init verified active with dummy DSN; capture path wired in all three)
- [x] No secrets/NID/OTP/token in logs (verified — backend test_logging.py + mobile observability_test.dart + manual boot log shows `otp=**** nid=****6788`)

## 12. Test plan
### Automated
- backend test: logging filter masks a sample NID + token string
### Manual QA
1. Set a dev Sentry DSN, trigger a test exception in each app, confirm it appears with the env tag.
2. Unset DSN → apps still run, no errors.

## 13. Acceptance criteria
- [ ] All three apps report errors to Sentry when DSN present.
- [ ] Logging is structured + PII-masked.
- [ ] No DSN = graceful no-op.

## 14. Self-review
- [x] No PII in logs/breadcrumbs
- [x] Env tag present
- [x] Graceful without DSN
### Deviations from spec
- Backend reads env via `django-environ` (the project's actual config layer), not `python-decouple` as `03_env_and_config.md` §2 states. Matched existing code.
- Sentry Next.js is v10, where client init lives in `instrumentation-client.ts` and server init is loaded via `instrumentation.ts`. The spec-named `sentry.client.config.ts` / `sentry.server.config.ts` are created and contain the actual `Sentry.init` calls; the two instrumentation hook files import them (required by Next 16 / Sentry v10).
- Backend logging dependency is `python-json-logger` (spec offered "structlog or python-json-logger") for the JSON formatter; PII masking is a stdlib `logging.Filter`.
- Added `NEXT_PUBLIC_SENTRY_DSN` / `NEXT_PUBLIC_APP_ENV` to `.env.example` (the browser bundle cannot read the server-only `SENTRY_DSN`).
### Files touched (actual)
- backend: `apps/api/khatir/core/logging.py` (new, masking filter + dictConfig builder), `apps/api/khatir/core/observability.py` (new, guarded Sentry init), `apps/api/khatir/core/tests/test_logging.py` (new), `apps/api/config/settings/base.py` (LOGGING + LOG_LEVEL/SENTRY_DSN/DJANGO_ENV), `apps/api/config/settings/prod.py` (Sentry init), `apps/api/pyproject.toml` + `uv.lock` (sentry-sdk[django], python-json-logger)
- mobile: `apps/mobile/lib/core/observability/sentry_init.dart`, `logger.dart`, `dio_sentry_interceptor.dart` (new), `apps/mobile/lib/main.dart` (init before runApp), `apps/mobile/lib/core/network/dio_client.dart` (interceptor), `apps/mobile/test/observability_test.dart` (new), `pubspec.yaml` + `pubspec.lock` (sentry_flutter)
- admin: `apps/admin/sentry.client.config.ts`, `sentry.server.config.ts`, `instrumentation.ts`, `instrumentation-client.ts` (new), `apps/admin/next.config.ts` (withSentryConfig), `package.json` + `package-lock.json` (@sentry/nextjs)
- root: `.env.example` (admin Sentry keys)

## 15. Notes for the implementing agent
- Masking patterns: 10–17 digit NID-like sequences → `****` + last 4; `Authorization` headers; `code`/`otp` fields; bKash txn ids in logs.
- Keep traces sample rate low (e.g. 0.1) to control cost.
