// Next.js client instrumentation hook: loads the Sentry browser config
// (T-015). The init inside is gated on NEXT_PUBLIC_SENTRY_DSN, so this is a
// no-op when no DSN is configured.
export { onRouterTransitionStart } from "./sentry.client.config";

import "./sentry.client.config";
