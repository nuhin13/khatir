import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig: NextConfig = {
  output: "standalone",
  // The shared design-tokens package is a workspace source dependency that
  // ships untranspiled TS; let Next transpile it for the admin build.
  transpilePackages: ["@khatir/design-tokens"],
};

// Wrap with Sentry (T-015). Build-time instrumentation is harmless without a
// DSN — runtime init is gated on SENTRY_DSN / NEXT_PUBLIC_SENTRY_DSN in the
// sentry.*.config.ts files, so a missing DSN is a graceful no-op.
export default withSentryConfig(nextConfig, {
  silent: !process.env.CI,
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  // Do not require Sentry source-map upload credentials at build time.
  widenClientFileUpload: true,
});
