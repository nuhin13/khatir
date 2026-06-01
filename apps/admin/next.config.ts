import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  // The shared design-tokens package is a workspace source dependency that
  // ships untranspiled TS; let Next transpile it for the admin build.
  transpilePackages: ["@khatir/design-tokens"],
};

export default nextConfig;
