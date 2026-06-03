---
id: T-011
epic: EPIC-03
title: Add-building wizard steps 3–4 (units generator, review, save)
layer: mobile
size: M
status: in-progress
preferred_agent: claude-code
depends_on: [T-010]
blocks: [T-014]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-011 · Add-building wizard steps 3–4 (units generator, review, save)

## 1. Feature goal
Build steps 3 (units generator) and 4 (review + save) of the wizard: floors × per-floor with numbering scheme, custom/removable units, a review summary, and the save that persists building + units via the API.

## 2. Business logic
Per `addBuilding` design steps 3–4. Step 3: steppers for floors and flats/floor, scheme toggle (letter `1A` / number `101`), live unit-label preview, add-custom + remove-individual. Step 4: review card (building, area, address, pin, unit list) → Save → POST building then generate units (or one combined call) → route to portfolio. UI generation must match backend (T-004); parity verified in T-014.

## 3. What this task DOES
- Step 3 (units generator) + Step 4 (review) views using the wizard controller.
- Client-side unit-label generation mirroring the backend pure function.
- Save action: create building (T-003) + generate units (T-004) → navigate to portfolio with success.
- Widget tests for steps 3–4 + save.

## 5. Files & changes
### Add
- `features/properties/presentation/wizard/{step3_units.dart,step4_review.dart,unit_label_gen.dart}`
- ARB keys; `test/wizard_steps34_test.dart`
### Update
- `add_building_controller.dart` (units state + save)

## 6. Database changes
None (calls APIs).
## 7. API changes
Consumes POST /buildings + /buildings/{id}/units/generate.

## 8. UI changes
- **Design source:** `addBuilding` steps 3–4 — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('addBuilding')` bStep 3–4
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/properties/add` (steps 3–4)
- Translate steppers + scheme toggle + unit chips + review card; values from packages/design-tokens
- States: data, saving (loading), error
- Navigation: back → step 2; save → `/landlord/home` portfolio (or `/properties` list) with success toast
- i18n keys: `wizard_floors`, `wizard_per_floor`, `wizard_scheme_letter/number`, `wizard_add_custom`, `wizard_review_*`, `wizard_save` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] step3 steppers (floors, per-floor) + scheme toggle + live labels
- [x] add-custom + remove-individual units
- [x] step4 review card (all wizard data + unit list)
- [x] save → create building + generate units → portfolio
- [x] client label gen mirrors backend (parity in T-014)
- [x] saving/error states
- [x] ARB bn + en; widget tests
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment

## 12. Test plan
### Automated
- wizard_steps34_test → label gen for both schemes; remove/add custom; save calls correct APIs
### Manual QA
1. 3 floors × 2, letter scheme → 1A,1B,2A,2B,3A,3B; remove 2B; add custom 8B; review; save → portfolio shows building with units.

## 13. Acceptance criteria
- [~] Steps 3–4 match design; save persists building+units; labels match backend.
  (label gen verified against the backend's own pytest vectors in
  `properties/tests/test_unit_generation.py`; analyze/test NOT run — no
  Flutter/Dart toolchain in this env.)
- [x] **Screen `addBuilding` fully built** (all 4 steps) — host now renders
  step1→step4; placeholder removed.
- [ ] Test + analyze pass — BLOCKED: no Flutter/Dart toolchain in this environment.

## 14. Self-review
- [x] Label gen parity with backend: `unit_label_gen.dart` is a line-for-line
  port of `generate_unit_labels` (`floors×perFloor`, letter `f+A,B…` / number
  `f*100+(p+1)`, custom appended, removed filtered, first-occurrence dedup).
  Cross-checked against the backend's pytest vectors (1A,1B,2A,2B,3A,3B /
  101,102,201,202 / custom+removed). T-014 asserts shared-vector parity.
- [x] All colours/spacing/radii/fonts via `packages/design-tokens` + theme — no
  prototype hex/px hardcoded (steppers, scheme toggle, chips, review card,
  error banner, saving spinner all use KhatirColors/Spacing/Radius/Fonts).
- [x] Save is transactional client-side: building create → unit generate; if
  generate fails the just-created building is deleted (best-effort) so the
  portfolio never shows a unit-less building, and the error is surfaced for retry.
### Deviations from spec
- **Blocker:** no Flutter/Dart toolchain in this environment (`flutter`/`dart`
  not on PATH; `~/Downloads/flutter` absent) — identical to EPIC-03 T-007..T-013.
  `flutter gen-l10n`, `flutter analyze`, `flutter test` could not be run. The
  generated `app_localizations*.dart` were hand-edited to match the gen-l10n
  output (mirroring how T-010 did it). DoD test-pass gate unconfirmed → status
  `in-progress` per the finish protocol.
- "+ custom" uses a small `AlertDialog` text-entry (`8B`, `2001`) rather than
  the prototype's cycle-through-a-pool stub, which only existed because the HTML
  prototype had no text input. Same controller path (`addCustomLabel`).
- Save routes to `/properties` (PortfolioScreen.routePath) — the committed
  portfolio route — matching the prototype's `go('portfolio')`; the task's
  "(or /landlord/home)" alternative was not needed.
### Files touched (actual)
- Add: `lib/features/properties/presentation/wizard/unit_label_gen.dart`
- Add: `lib/features/properties/presentation/wizard/step3_units.dart`
- Add: `lib/features/properties/presentation/wizard/step4_review.dart`
- Add: `test/wizard_steps34_test.dart`
- Update: `lib/features/properties/presentation/wizard/add_building_controller.dart`
  (units mutations: floors/perFloor steppers, scheme, add/remove custom; derived
  `unitLabels`, `step3Valid`)
- Update: `lib/features/properties/presentation/wizard/wizard_host.dart`
  (wire steps 3–4; real titles; remove placeholder)
- Update: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb` + hand-edited generated
  `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`,
  `app_localizations_bn.dart` (wizard step-3/4 keys)

## 15. Notes for the implementing agent
- Letter: floor+A,B per perFloor; Number: floor×100+i. MUST match backend unit_generation (T-004). T-014 cross-checks. Save can be two calls (building then generate) or one combined — keep it transactional client-side (if generate fails, surface error, don't leave a building with no units silently).
