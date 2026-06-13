// Next.js instrumentation hook: loads the Sentry server config on the
// appropriate runtime and wires request-error capture (T-015). The underlying
// init is a no-op when no DSN is set, so this is safe without a Sentry account.
import * as Sentry from "@sentry/nextjs";

export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs" || process.env.NEXT_RUNTIME === "edge") {
    await import("./sentry.server.config");
  }
}

export const onRequestError = Sentry.captureRequestError;
