---
id: T-008
epic: EPIC-03
title: Shared map-pin widget (flutter_map + OSM)
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-008]
blocks: [T-010]
external_services: [openstreetmap]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Shared map-pin widget (flutter_map + OSM)

## 1. Feature goal
A reusable tap-to-drop-pin map widget (OSM tiles) returning lat/lng + a best-effort address, used by the add-building wizard and reusable later.

## 2. Business logic
Per design `addBuilding` step 2: a map the user taps to drop a pin; selecting a pin fills the address (auto) but address remains editable. OSM tiles (free, attribution shown). Optional — skipping the map is allowed.

## 3. What this task DOES
- `core/widgets/k_map_picker.dart` (flutter_map + OSM, tap → pin → callback with LatLng).
- Reverse-geocode hook (pluggable; can be a stub returning coords-as-text initially, real geocoder later).
- Attribution overlay. Widget test (renders, tap emits LatLng).

## 5. Files & changes
### Add
- `lib/core/widgets/k_map_picker.dart`
- `test/map_picker_test.dart`
### Update
- `pubspec.yaml` (flutter_map, latlong2)

## 6. Database changes
None.
## 7. API changes
None (client-side; geocoding optional/pluggable).
## 8. UI changes
- **Design source:** `addBuilding` step 2 map block — `docs/design/khatir-ui/proto/screens-landlord.js`
- Surface: mobile · **Lane:** 🟢 mobile
- Component: KMapPicker
- States: loading tiles, data (pin), empty (no pin yet)
- Values from packages/design-tokens; OSM attribution required

## 9. External services
OpenStreetMap tile server (free, no key). Be polite with request volume; cache.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] KMapPicker (flutter_map + OSM tiles)
- [x] tap → drop pin → onChanged(LatLng)
- [x] pluggable reverse-geocode (stub ok now)
- [x] OSM attribution shown
- [x] Widget test
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment

## 12. Test plan
### Automated
- map_picker_test → renders; simulated tap emits LatLng
### Manual QA
1. Tap map → pin drops → callback fires with coords.

## 13. Acceptance criteria
- [x] Reusable map-pin widget with OSM + attribution; tests written. (analyze/test not run — no toolchain here)

## 14. Self-review
- [x] Attribution present; tiles cached; tokens used
### Deviations from spec
- Prototype shows a Google-Maps mock; per the task note we use OSM tiles
  (`tile.openstreetmap.org`) with the required `© OpenStreetMap contributors`
  attribution via `RichAttributionWidget`. Visual parity comes from tokens
  (sage/rose, card radius, soft shadow), not Google branding.
- Reverse-geocode is a pluggable `ReverseGeocoder` typedef; the default
  `coordsAsTextGeocoder` renders coords-as-text (e.g. `23.8103°N, 90.4125°E`).
  Address is returned via `onAddressResolved` so the caller keeps it editable.
- analyze + test were NOT executed: this environment has no Flutter/Dart
  toolchain. flutter_map v8 API usage verified against current upstream docs.
### Files touched (actual)
- Add: lib/core/widgets/k_map_picker.dart
- Add: test/map_picker_test.dart
- Update: pubspec.yaml (flutter_map ^8.3.0, latlong2 ^0.10.1)
- Update: lib/l10n/app_en.arb, lib/l10n/app_bn.arb (map_picker_* keys)

## 15. Notes for the implementing agent
- The prototype shows a Google-Maps-styled mock; we use OSM (free, no key) — visual parity via our tokens, not Google branding. Address stays editable even when pin auto-fills it.
