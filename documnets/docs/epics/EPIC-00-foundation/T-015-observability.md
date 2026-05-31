---
id: T-015
epic: EPIC-00
title: Observability (Sentry + structured logging)
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-004, T-007, T-009]
blocks: []
external_services: [sentry]
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] Backend Sentry init (env-tagged) + structured logging + PII masking filter
- [ ] Mobile Sentry init + logger + dio error reporting (PII-safe)
- [ ] Admin Sentry (client+server)
- [ ] Missing DSN → graceful no-op in all three
- [ ] A deliberate test error surfaces in Sentry when DSN set
- [ ] No secrets/NID/OTP/token in logs (verified)

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
- [ ] No PII in logs/breadcrumbs
- [ ] Env tag present
- [ ] Graceful without DSN
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Masking patterns: 10–17 digit NID-like sequences → `****` + last 4; `Authorization` headers; `code`/`otp` fields; bKash txn ids in logs.
- Keep traces sample rate low (e.g. 0.1) to control cost.
