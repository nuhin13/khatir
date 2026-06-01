# Decisions

Architecture and process decisions, newest at bottom. One entry per decision.

- 2026-06-02 · Mono-repo single-repo layout chosen (see architecture 02).
- 2026-06-02 · Docs currently live under `documnets/` (pre-existing, misspelled directory name kept as-is for now; not renamed to `docs/` to avoid breaking existing references). Architecture docs are at `documnets/docs/architecture/`.
- 2026-06-02 · [EPIC-00 T-009] Admin app pins ESLint to `^9.39.4` (latest 9.x), not the newer ESLint 10.4.1. Hard incompatibility: `eslint-config-next@16.2.7` bundles `eslint-plugin-react@7.x`, which calls the `context.getFilename()` API removed in ESLint 10, throwing on every lint run. eslint-config-next's peer range is `eslint >=9`; the Next ecosystem has not yet shipped an ESLint-10-compatible plugin set. Revisit when eslint-config-next supports ESLint 10.
- 2026-06-02 · [EPIC-00 T-009] Tailwind v4 consumes the shared `@khatir/design-tokens` preset via `@config "../../tailwind.config.ts"` in `globals.css`; the config imports the preset through the package `exports` map. The Tailwind/oxide engine resolves this correctly (verified: `bg-sage` compiles to `#7ba084`, etc.). Turbopack emits a cosmetic, non-fatal "Module not found" warning during `next build` because it independently parses the `@config`-referenced file in its own app-rooted module graph and cannot follow the symlinked workspace package's subpath export. The build succeeds and tokens compile; accepted as a known Turbopack limitation.
