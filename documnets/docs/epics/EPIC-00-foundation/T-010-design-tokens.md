---
id: T-010
epic: EPIC-00
title: Shared design-tokens package
layer: packages
size: S
status: done
preferred_agent: codex
depends_on: [T-001]
blocks: [T-008, T-009]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Shared design-tokens package

## 1. Feature goal
Create a single source of truth for the Notun Din design tokens (colors, radii, spacing, font families) in `packages/design-tokens/`, consumable by both the Flutter app and the Next.js admin, so the palette never drifts between surfaces.

## 2. Business logic
Tokens are defined once as data (JSON) plus generated language bindings. Flutter reads a Dart file; admin reads the JSON into Tailwind config. Changing a token in one place updates both apps.

## 3. What this task DOES
- `packages/design-tokens/tokens.json` — canonical tokens (colors, radii, spacing, fonts) from the Notun Din palette.
- `packages/design-tokens/dart/khatir_tokens.dart` — Dart constants (consumed by Flutter T-008).
- `packages/design-tokens/ts/tokens.ts` + a Tailwind preset (consumed by admin T-009).
- A tiny generator script (`generate.mjs` or `generate.py`) that regenerates the Dart + TS from `tokens.json`, so JSON stays the single source.
- README explaining how to add/change a token and regenerate.

## 4. What this task does NOT do
- Does not wire into the apps (that's T-008 for Flutter, T-009 for admin) — it just publishes the tokens.

## 5. Files & changes
### Add
- `packages/design-tokens/tokens.json`
- `packages/design-tokens/dart/khatir_tokens.dart`
- `packages/design-tokens/ts/tokens.ts`
- `packages/design-tokens/ts/tailwind-preset.js`
- `packages/design-tokens/generate.mjs` (or .py)
- `packages/design-tokens/README.md`
### Update
- remove `packages/.gitkeep`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
No UI directly (provides tokens others consume).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [x] tokens.json with full Notun Din palette + radii + spacing + font families
- [x] Dart bindings generated
- [x] TS bindings + Tailwind preset generated
- [x] generate script regenerates both from JSON
- [x] README with add-a-token instructions
- [x] generated outputs committed

## 12. Test plan
### Manual QA
1. Change a color in tokens.json, run the generator, confirm both Dart + TS outputs update.

## 13. Acceptance criteria
- [x] tokens.json is the single source; Dart + TS generated from it.
- [x] Palette values match Notun Din exactly.

## 14. Self-review
- [x] One source of truth (JSON)
- [x] Generator reproducible
### Deviations from spec
- Added `package.json` (not listed in §5) so the package is consumable as `@khatir/design-tokens` and exposes an `npm run generate` script. The package is intentionally NOT `type: module` so the Tailwind preset can use CommonJS `module.exports` (Tailwind requirement); the generator is `.mjs` so it stays ESM regardless.
- tokens.json includes the full prototype `:root` set (incl. `ink2`, `lineDk`, `mutedDk`, `danger`/`dangerBg`, the `xs/sm/md/xl` radii and `pill`) beyond the minimal list in §15, so no surface drifts from the prototype. The §15 named values (sage/rose/butter/cream/ink, radii card 22 / button 999 / chip 999 / tile 16, fonts) are all present and verified against `styles/khatir.css`.
### Files touched (actual)
- Add: packages/design-tokens/{tokens.json, generate.mjs, package.json, README.md, dart/khatir_tokens.dart, ts/tokens.ts, ts/tailwind-preset.js}
- Delete: packages/.gitkeep

## 15. Notes for the implementing agent
- Palette: sage #7BA084, sageDk #5C8067, sageBg #E8F0EA, rose #E89B8B, roseDk #C9755F, roseBg #FBE9E3, butter #F4D58D, butterDk #D9B45F, butterBg #FBF1D8, cream #FBF6EE, card #FFFFFF, line #EFE6D8, ink #2C3530, muted #8C8578.
- Radii: card 22, button 999, chip 999, tile 16. Fonts: title "Plus Jakarta Sans", bnBody "Hind Siliguri", hand "Caveat".
