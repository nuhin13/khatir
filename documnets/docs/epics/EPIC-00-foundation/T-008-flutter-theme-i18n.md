---
id: T-008
epic: EPIC-00
title: Flutter theme tokens + i18n (bn/en)
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007, T-010]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-02
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Flutter theme tokens + i18n (bn/en)

## 1. Feature goal
Implement the Notun Din design system in Flutter (colors, text styles, radii, shared widgets) sourced from the shared design-tokens package, and set up internationalization with Bangla as default and English as toggle.

## 2. Business logic
Theme tokens come from `packages/design-tokens` (T-010) so all three apps stay in sync. All user-facing strings go through gen-l10n ARB files; Bangla (`bn`) is the default locale, English (`en`) is secondary. No hardcoded strings or hex colors anywhere.

## 3. What this task DOES
- `lib/core/theme/colors.dart` (sage/rose/butter/cream/ink from tokens), `text_styles.dart` (Plus Jakarta Sans titles, Hind Siliguri Bangla body, Caveat accents), `app_theme.dart` (ThemeData with radii/shadows).
- Wire the theme into `app.dart`.
- gen-l10n setup: `l10n.yaml`, `lib/l10n/app_bn.arb` (default), `lib/l10n/app_en.arb`.
- A `localeProvider` (Riverpod) to toggle locale at runtime; persists choice in secure storage.
- Shared widgets: `KButton`, `KCard`, `KChip`, `KBottomNav` styled with tokens.
- Update the placeholder screen to use theme + a localized string + a locale toggle button (proves the system end-to-end).
- Bangla numeral formatting helper via intl.

## 4. What this task does NOT do
- No real feature screens.

## 5. Files & changes
### Add
- `lib/core/theme/colors.dart`, `text_styles.dart`, `app_theme.dart`
- `lib/core/widgets/k_button.dart`, `k_card.dart`, `k_chip.dart`, `k_bottom_nav.dart`
- `lib/core/i18n/locale_provider.dart`
- `l10n.yaml`, `lib/l10n/app_bn.arb`, `lib/l10n/app_en.arb`
- `test/theme_i18n_test.dart`
### Update
- `lib/app.dart` — theme + localizationsDelegates + supportedLocales + localeProvider
- `lib/features/placeholder/.../placeholder_screen.dart` — use theme + localized string + locale toggle
- `pubspec.yaml` — fonts (Plus Jakarta Sans, Hind Siliguri, Caveat), `generate: true`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
- Surface: mobile
- Screen: placeholder updated to demonstrate theme + bn/en toggle
- States: data
- i18n keys: `common_app_name`, `common_toggle_language`, `placeholder_welcome` (bn + en)

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] Color tokens from design-tokens package (no inline hex)
- [ ] Text styles with the three brand fonts bundled
- [ ] app_theme.dart radii (16-24 cards, 999 buttons) + soft shadows
- [ ] gen-l10n configured; bn default, en secondary
- [ ] localeProvider toggles + persists
- [ ] KButton/KCard/KChip/KBottomNav shared widgets
- [ ] placeholder uses theme + localized string + toggle
- [ ] Bangla numeral formatting helper
- [ ] analyze + test pass

## 12. Test plan
### Automated
- theme_i18n_test → app builds with theme; switching locale changes a rendered string from Bangla to English
### Manual QA
1. Launch → UI in Bangla; tap toggle → English; restart → choice persisted.

## 13. Acceptance criteria
- [ ] Notun Din theme applied from shared tokens.
- [ ] bn default, en toggle works + persists.
- [ ] No hardcoded strings/colors in placeholder.

## 14. Self-review
- [ ] Tokens sourced from packages/design-tokens
- [ ] All strings via ARB
- [ ] Fonts bundled + licensed (Google Fonts OFL)
### Deviations from spec
- Fonts: font families (Plus Jakarta Sans / Hind Siliguri / Caveat) are wired via
  `fontFamily` from the tokens (`KhatirFonts`), but the OFL `.ttf` binaries are NOT
  bundled because they are not present in the repo and cannot be fetched offline.
  The `fonts:` asset block in `pubspec.yaml` is committed as a ready-to-use template
  (commented out); drop the `.ttf` files under `assets/fonts/` and uncomment to bundle.
  Flutter falls back to the platform default for these families until then.
- gen-l10n output path: Flutter 3.44 no longer emits to the synthetic
  `package:flutter_gen`; generated `AppLocalizations` lands in `lib/l10n/`. Imports use
  the relative `l10n/app_localizations.dart` path accordingly.
- Added `lib/core/i18n/bangla_numerals.dart` (helper file) and `lib/core/theme/colors.dart`
  is a thin `typedef AppColors = KhatirColors;` re-export (single source of truth stays the
  tokens package).
### Files touched (actual)
- Add: lib/core/theme/colors.dart, text_styles.dart, app_theme.dart
- Add: lib/core/widgets/k_button.dart, k_card.dart, k_chip.dart, k_bottom_nav.dart
- Add: lib/core/i18n/locale_provider.dart, bangla_numerals.dart
- Add: l10n.yaml, lib/l10n/app_bn.arb, app_en.arb (+ generated app_localizations*.dart)
- Add: test/theme_i18n_test.dart
- Update: lib/app.dart, lib/features/placeholder/.../placeholder_screen.dart, pubspec.yaml
- Delete: test/placeholder_screen_test.dart (superseded by theme_i18n_test.dart)

## 15. Notes for the implementing agent
- Fonts: bundle Plus Jakarta Sans, Hind Siliguri, Caveat as assets (OFL licensed) rather than runtime-fetching, so the app works offline.
- Palette: sage #7BA084, sageDk #5C8067, rose #E89B8B, roseDk #C9755F, butter #F4D58D, cream #FBF6EE, ink #2C3530 — but READ them from the tokens package, don't re-hardcode.
- Keep ARB keys in the `feature_screen_element` convention.
