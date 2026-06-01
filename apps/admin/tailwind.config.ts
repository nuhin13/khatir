import type { Config } from "tailwindcss";
import preset from "@khatir/design-tokens/tailwind-preset";

// Shared Notun Din design tokens — single source of truth (packages/design-tokens).
// The preset injects colors / radii / spacing / fontFamily into the theme; the
// `@config` directive in src/app/globals.css loads this file into the Tailwind
// pipeline. The Tailwind engine resolves the preset via the package `exports`
// map, so utilities like `bg-sage` / `text-ink` emit the exact token hex values.
const config: Config = {
  presets: [preset as Config],
  content: ["./src/**/*.{ts,tsx,mdx}"],
};

export default config;
