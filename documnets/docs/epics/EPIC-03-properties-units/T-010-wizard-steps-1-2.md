---
id: T-010
epic: EPIC-03
title: Add-building wizard steps 1–2 (name/area, address/map)
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007, T-008]
blocks: [T-011]
external_services: [openstreetmap]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Add-building wizard steps 1–2 (name/area, address/map)

## 1. Feature goal
Build the first two steps of the 4-step add-building wizard: name + area (step 1) and address + optional map pin (step 2), with shared wizard state and the step progress bar.

## 2. Business logic
Per `addBuilding` design. Step 1: building name (required) + area chips (from `area_options` config). Step 2: optional "pick on map" (KMapPicker, T-008) that auto-fills an editable address; address required to proceed. One Riverpod wizard controller holds all state across steps (mirrors prototype's single-state approach). Progress bar shows step N/4.

## 3. What this task DOES
- `features/properties/presentation/wizard/add_building_controller.dart` (full wizard state: name, area, addr, lat/lng, units config).
- Step 1 + Step 2 screens/views + the shared progress header.
- Area chips from public config (`area_options`). Map step uses KMapPicker.
- Route `/properties/add` (wizard host). Back/next nav between steps. Widget tests for steps 1–2.

## 4. What this task does NOT do
- Steps 3–4 (T-011). No save yet.

## 5. Files & changes
### Add
- `features/properties/presentation/wizard/{add_building_controller.dart,wizard_host.dart,step1_name_area.dart,step2_address_map.dart,wizard_progress.dart}`
- ARB keys; `test/wizard_steps12_test.dart`
### Update
- `app_router.dart` — `/properties/add`

## 6. Database changes
None.
## 7. API changes
Reads `area_options` from /config/public.

## 8. UI changes
- **Design source:** screen `addBuilding` steps 1–2 — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('addBuilding')`, bStep 1–2)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/properties/add`
- Translate progress bar + step1 (name + area chips) + step2 (map pick + address); values from packages/design-tokens
- States: data, validation errors (name/area/address required), map loading
- Navigation: back → home/prev step; next → step 2 → (T-011) step 3
- i18n keys: `wizard_step_x_of_4`, `building_name`, `building_area`, `building_address`, `wizard_pick_on_map`, `wizard_next` (bn + en)

## 9. External services
OSM via KMapPicker.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] add_building_controller holds full wizard state (name/area/addr/lat/lng + units config for T-011)
- [x] wizard_host + progress bar (N/4)
- [x] step1: name (required) + area chips from config (`area_options` via /config/public)
- [x] step2: map pick (KMapPicker) auto-fills editable address; address required
- [x] back/next nav; validation gating
- [x] route /properties/add
- [x] ARB bn + en; widget tests steps 1–2
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment

## 12. Test plan
### Automated
- wizard_steps12_test → can't advance without name/area; step2 requires address; map pin fills address
### Manual QA
1. Start wizard → fill name+area → next → drop pin → address fills → editable → next.

## 13. Acceptance criteria
- [~] Steps 1–2 match design; validation correct; map pin works; state persists across steps.
  (analyze/test NOT verified — no Flutter/Dart toolchain available in this env.)
- [ ] Test + analyze pass — BLOCKED: no Flutter/Dart toolchain in this environment.

## 14. Self-review
- [x] Single wizard controller (`AddBuildingController`, AutoDisposeNotifier) holds
  all four steps' state; back/next preserve input.
- [x] All colours/spacing/radii/fonts via `packages/design-tokens` + theme text
  styles — no prototype hex/px hardcoded.
- [x] Area chips come from `area_options` (`/config/public`), not a hardcoded list.
### Deviations from spec
- **Blocker:** no Flutter/Dart toolchain exists in this environment
  (`flutter`/`dart` not on PATH; the `~/Downloads/flutter` referenced by the
  shell profile is absent), so `flutter gen-l10n`, `flutter analyze`, and
  `flutter test` could not be run — same blocker as EPIC-03/T-007, T-008, T-009,
  T-012, T-013. The gen-l10n outputs (`app_localizations*.dart`) were hand-edited
  to match the committed generator output, mirroring how T-007 hand-wrote the
  freezed parts. The DoD test-pass gate therefore cannot be confirmed; status is
  `in-progress` per the finish protocol.
- `PublicConfig` was extended with `areaOptions` (parsed from `area_options`)
  rather than introducing a separate provider, keeping a single bootstrap-config
  source. Falls back to the full `Area` enum when unseeded/missing.
- Step views are plain `ConsumerStatefulWidget`s hosted by `WizardHost`; the host
  owns the shared top bar + progress so steps stay focused on their fields.
- Reused the existing top-level `areaLabel(...)` helper from `portfolio_screen.dart`
  (T-012) for chip labels instead of duplicating the Area→l10n switch.
### Files touched (actual)
- Add: `lib/features/properties/presentation/wizard/add_building_controller.dart`
- Add: `lib/features/properties/presentation/wizard/wizard_host.dart`
- Add: `lib/features/properties/presentation/wizard/wizard_progress.dart`
- Add: `lib/features/properties/presentation/wizard/wizard_widgets.dart`
- Add: `lib/features/properties/presentation/wizard/step1_name_area.dart`
- Add: `lib/features/properties/presentation/wizard/step2_address_map.dart`
- Add: `test/wizard_steps12_test.dart`
- Update: `lib/core/router/app_router.dart` (route `/properties/add`)
- Update: `lib/features/properties/presentation/screens/landlord_home_screen.dart`
  (add-building CTA → wizard)
- Update: `lib/core/config/public_config_provider.dart` (`areaOptions`)
- Update: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb` + hand-edited generated
  `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`,
  `app_localizations_bn.dart` (wizard_* / building_* keys)

## 15. Notes for the implementing agent
- 4 steps total: 1 name+area, 2 address+map, 3 units, 4 review (T-011 does 3–4). Progress bar shows all 4. Area chips list from `area_options` config (T-006), not hardcoded.
