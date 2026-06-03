---
id: T-013
epic: EPIC-03
title: Unit detail screen
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

# T-013 · Unit detail screen

## 1. Feature goal
Show a single unit: rent, type, status, amenities, and the current tenant/lease summary (placeholder until EPIC-04/06), with actions to edit the unit and add a tenant.

## 2. Business logic
Per `unit` design. Edit rent/type/status/amenities (PATCH unit). "Add tenant" → EPIC-04 flow (placeholder route until then). Tenant/lease section shows empty state now, filled by EPIC-06.

## 3. What this task DOES
- `features/properties/presentation/screens/unit_detail_screen.dart` matching `unit`.
- Editable rent/status/type/amenities; add-tenant CTA; tenant/lease placeholder region.
- Loading/error/empty/data. Widget test.

## 5. Files & changes
### Add
- `unit_detail_screen.dart`; ARB; `test/unit_detail_test.dart`
### Update
- router `/properties/unit/:id`

## 6. Database changes
None.
## 7. API changes
Consumes GET/PATCH /units/{id}.

## 8. UI changes
- **Design source:** screen `unit` — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('unit')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/properties/unit/:id`
- Translate unit info + edit controls + tenant section; values from packages/design-tokens
- States: loading/error/data; tenant section empty until EPIC-06
- Navigation: add tenant → `/tenants/add` (placeholder until EPIC-04)
- i18n keys: `unit_rent`, `unit_status`, `unit_type`, `unit_amenities`, `unit_add_tenant`, `unit_no_tenant` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] unit_detail_screen matches design
- [x] editable rent/status/type/amenities (PATCH)
- [x] add-tenant CTA (placeholder route)
- [x] tenant/lease placeholder region (TODO EPIC-06)
- [x] all states (loading/error/data — no empty: a unit always exists or 404s)
- [x] ARB bn + en; widget test
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this environment

## 12. Test plan
### Automated
- unit_detail_test → renders unit; edit status persists; add-tenant routes
### Manual QA
1. Open unit → change status vacant→occupied → persists.

## 13. Acceptance criteria
- [x] Unit detail matches design; edits persist (PATCH replaces state in place); states present.
- [x] **Screen `unit` built** (ledger row).
- [~] Test + analyze pass — tests written; NOT verified (no Flutter/Dart toolchain in env).

## 14. Self-review
- [x] Matches design (sage-gradient rent hero + facts grid + tenant region); all
      values from `packages/design-tokens`; tenant region marked `// TODO(EPIC-06)`.
### Deviations from spec
- Edit surface: the prototype `unit` screen shows its edit affordance as a
  pencil in the top bar; rent/status/type/amenities are edited via a bottom
  sheet (`_EditUnitSheet`) opened from that pencil, plus inline tap-to-PATCH
  menus on the status and type tiles for the common quick-edit. Amenities are
  comma-separated text in the sheet (free-form, matching the backend list field).
- The prototype's tenant rowcard + quick-action grid (DMP/Rent/Verify/Warning)
  belong to EPIC-04/05/07/17/20; per this task's §8 the tenant/lease region is a
  clean empty-state placeholder for EPIC-06, with the add-tenant CTA → `/tenants/add`.
- No "empty" state: a unit always exists or the request 404s into the error
  branch, so the screen has loading/error/data (the three meaningful states).
- A new `UnitDetailController` family + `unitDetailProvider` were added to
  `properties_providers.dart` (the existing `unitProvider` is a read-only
  `FutureProvider`; the detail screen needs PATCH-and-update-in-place).
- l10n: no Flutter toolchain to run `gen-l10n`, so the generated
  `app_localizations*.dart` getters were hand-written to match the committed
  generator output (same as the ARB edits), faithfully following the existing
  style in those files.
- **Blocker:** no Flutter/Dart toolchain in this environment (`flutter`/`dart`
  not on PATH; `~/Downloads/flutter` absent), so `flutter analyze` and
  `flutter test` could not be run — identical blocker to EPIC-03/T-007,
  EPIC-02/T-008, EPIC-03/T-008. The DoD test-pass gate cannot be confirmed, so
  status is `in-progress` per the finish protocol.
### Files touched (actual)
- Add: `lib/features/properties/presentation/screens/unit_detail_screen.dart`
- Add: `test/unit_detail_test.dart`
- Update: `lib/features/properties/data/properties_providers.dart` (UnitDetailController + unitDetailProvider)
- Update: `lib/core/router/app_router.dart` (`/properties/unit/:id` → real screen)
- Update: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb` (unit_* keys)
- Update: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_bn.dart` (generated getters, hand-written)

## 15. Notes for the implementing agent
- Keep the tenant/lease block as a clean empty-state with a `// TODO(EPIC-06)` so leases drop in later without redesign.
