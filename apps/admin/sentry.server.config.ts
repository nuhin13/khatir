// Sentry server (Node/edge) initialisation for the admin portal (T-015).
//
// Gated on SENTRY_DSN: when unset, init() is never called, so the server runs
// with no Sentry account configured (graceful no-op, T-015 §3/§13). The
// environment tag (dev/staging/prod) is attached to every event.
import * as Sentry from "@sentry/nextjs";

const dsn = process.env.SENTRY_DSN ?? process.env.NEXT_PUBLIC_SENTRY_DSN;

if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.APP_ENV ?? process.env.DJANGO_ENV ?? "dev",
    // Keep tracing cost low (T-015 §15).
    tracesSampleRate: 0.1,
    // Never attach request headers / IP — no PII in events.
    sendDefaultPii: false,
  });
}
