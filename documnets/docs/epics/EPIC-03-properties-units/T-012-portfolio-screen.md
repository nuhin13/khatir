---
id: T-012
epic: EPIC-03
title: Portfolio list screen
layer: mobile
size: M
status: in-progress
preferred_agent: claude-code
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-012 · Portfolio list screen

## 1. Feature goal
Show the landlord's buildings with unit counts and occupancy, with entry points to add a building and open a unit.

## 2. Business logic
Per `portfolio` design. Lists buildings (name, area, units, occupied/vacant), tap → building's units → unit detail. Add-building CTA → wizard.

## 3. What this task DOES
- `features/properties/presentation/screens/portfolio_screen.dart` matching `portfolio`.
- Building cards (summary from /portfolio), expand/drill to units, add-building CTA.
- Loading/error/empty/data. Widget test.

## 5. Files & changes
### Add
- `portfolio_screen.dart`; ARB; `test/portfolio_screen_test.dart`
### Update
- router + landlord shell wiring as needed

## 6. Database changes
None.
## 7. API changes
Consumes /portfolio.

## 8. UI changes
- **Design source:** screen `portfolio` — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('portfolio')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/landlord/home` (portfolio view) or `/properties`
- Translate building cards + counts; values from packages/design-tokens
- States: loading/error/empty (no buildings → add CTA)/data
- Navigation: building → units → `/properties/unit/:id`; add → `/properties/add`
- i18n keys: `portfolio_title`, `portfolio_units`, `portfolio_occupied`, `portfolio_add_building`, `portfolio_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] portfolio_screen matches design
- [x] building cards with counts/occupancy
- [x] drill to units → unit detail (chips expand; tap → /properties/unit/:id)
- [x] add-building CTA → wizard (placeholder snackbar until T-010/T-011)
- [x] all states incl. empty
- [x] ARB bn + en; widget test
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this env

## 12. Test plan
### Automated
- portfolio_screen_test → renders buildings; empty state; tap navigates
### Manual QA
1. View portfolio; tap a building → units; tap unit → detail.

## 13. Acceptance criteria
- [ ] Portfolio matches design; navigation works; all states.
- [ ] **Screen `portfolio` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens; empty state friendly
### Deviations from spec
- **Route:** portfolio is registered as a top-level `/properties` route on the
  root navigator (reached by tapping the buildings/units stat tiles on the
  landlord home), not as a fourth shell tab — the landlord home already owns the
  `home` slot, and the prototype shows portfolio with a back button (`back:'home'`),
  i.e. a pushed full-screen view, not a tab.
- **Building card unit chips:** `BuildingSummary` (from `/portfolio`) carries
  only counts, not unit labels. Cards are therefore expandable: tapping a card
  header lazily loads that building's units via `buildingUnitsProvider`
  (`GET /buildings/{id}/units`) and renders the chip strip; tapping a chip drills
  to the unit. This matches the prototype's chip strip + per-unit navigation
  without inventing data the summary endpoint does not return. Floor count /
  English-name subtitle from the prototype are omitted (not in the wire schema).
- **Area label:** added `area_*` ARB keys (bn + en) and an `areaLabel()` helper
  mapping the typed `Area` enum to a localized string; the enum itself stays in
  `property_enums.dart` (only the human label lives in l10n).
- **Unit-detail route:** `/properties/unit/:id` is registered now as a
  `KShellPlaceholder` so the drill-down has a live target; T-013 replaces the
  builder with the real unit screen.
- **Blocker:** no Flutter/Dart toolchain exists in this environment
  (`flutter`/`dart` not on PATH; `~/Downloads/flutter` absent), the same blocker
  recorded by the dependency T-007. `flutter gen-l10n`, `flutter analyze`, and
  `flutter test` could not be run. The new ARB keys were therefore also applied
  by hand to the committed generated `app_localizations*.dart` files, matching
  the existing gen-l10n output format field-by-field. The DoD test-pass gate
  cannot be confirmed, so status is `in-progress` per the finish protocol.
### Files touched (actual)
- Add: `lib/features/properties/presentation/screens/portfolio_screen.dart`
- Add: `test/portfolio_screen_test.dart`
- Update: `lib/core/router/app_router.dart` (register `/properties` +
  `/properties/unit/:id`)
- Update: `lib/features/properties/presentation/screens/landlord_home_screen.dart`
  (buildings/units stat tiles open the portfolio)
- Update: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb` (+ generated
  `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_bn.dart`)

## 15. Notes for the implementing agent
- If the design shows portfolio as part of `home` vs a separate tab, follow the design; route accordingly.
