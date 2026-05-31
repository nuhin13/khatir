---
id: T-008
epic: EPIC-03
title: Shared map-pin widget (flutter_map + OSM)
layer: mobile
size: M
status: todo
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
- [ ] KMapPicker (flutter_map + OSM tiles)
- [ ] tap → drop pin → onChanged(LatLng)
- [ ] pluggable reverse-geocode (stub ok now)
- [ ] OSM attribution shown
- [ ] Widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- map_picker_test → renders; simulated tap emits LatLng
### Manual QA
1. Tap map → pin drops → callback fires with coords.

## 13. Acceptance criteria
- [ ] Reusable map-pin widget with OSM + attribution; tests + analyze pass.

## 14. Self-review
- [ ] Attribution present; tiles cached; tokens used
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- The prototype shows a Google-Maps-styled mock; we use OSM (free, no key) — visual parity via our tokens, not Google branding. Address stays editable even when pin auto-fills it.
