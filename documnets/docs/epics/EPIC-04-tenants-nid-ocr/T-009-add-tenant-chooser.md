---
id: T-009
epic: EPIC-04
title: Flutter add-tenant method chooser
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-03.T-007]
blocks: [T-010, T-012, T-013]
external_services: []
feature_flags: [voice_tenant_entry]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Flutter add-tenant method chooser

## 1. Feature goal
The entry screen for adding a tenant: choose NID photo (OCR), voice fill, or manual entry.

## 2. Business logic
Per `addTenant` design. Three method cards. Voice card hidden/disabled if `voice_tenant_entry` flag off. Each routes to its flow, carrying the target unit id.

## 3. What this task DOES
- `features/tenants/presentation/screens/add_tenant_screen.dart` matching `addTenant`.
- Method cards (OCR/voice/manual) with the design copy; route to /tenants/add/ocr|voice|manual with unit context.
- Flag-gate voice. Route `/tenants/add`. Widget test.

## 5. Files & changes
### Add
- add_tenant_screen.dart; ARB; test/add_tenant_test.dart
### Update
- app_router.dart `/tenants/add`; landlord shell FAB → here

## 6. Database changes
None.
## 7. API changes
Reads feature flag (config/public).

## 8. UI changes
- **Design source:** screen `addTenant` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('addTenant')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/add`
- Translate method chooser cards; values from packages/design-tokens
- States: data (+ voice hidden if flag off)
- Navigation: → ocr/voice/manual with unit id
- i18n keys: `add_tenant_title`, `add_tenant_ocr`, `add_tenant_voice`, `add_tenant_manual` (bn + en) — lift from `addTenant`

## 9. External services
None.
## 10. Feature flags
- voice_tenant_entry (hides voice card if off)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] add_tenant_screen matches design (3 method cards)
- [x] routes carry unit id
- [x] voice card flag-gated
- [x] route /tenants/add; FAB wired
- [x] ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- add_tenant_test → 3 cards (2 if flag off); tap routes with unit id
### Manual QA
1. From unit/home → add tenant → see 3 methods → pick OCR.

## 13. Acceptance criteria
- [x] Chooser matches design; routes correctly; flag respected.
- [x] **Screen `addTenant` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens; unit context passed
### Deviations from spec
- The `voice_tenant_entry` flag is read from the `flags` block of `/config/public`
  (added `voiceTenantEntry` to `PublicConfig`, default **on** to match the
  backend's task-declared default and avoid hiding voice in an unseeded env).
- The three method screens (OCR/voice/manual) land in later EPIC-04 tasks; they
  are registered as `KShellPlaceholder` sub-routes under `/tenants/add` so the
  chooser's routes resolve. The chooser routes to them by name, carrying the
  optional target unit id as a `?unit=` query parameter.
- Unit context: the home/manager FAB launches without a unit (chosen later in
  the flow, per §15); the unit-detail "Add tenant" CTA passes `?unit=<id>`.
### Files touched (actual)
- Add: `lib/features/tenants/presentation/screens/add_tenant_screen.dart`
- Add: `test/add_tenant_test.dart`
- Update: `lib/core/config/public_config_provider.dart` (voiceTenantEntry flag)
- Update: `lib/core/router/app_router.dart` (real /tenants/add + ocr/voice/manual sub-routes)
- Update: `lib/features/properties/presentation/screens/unit_detail_screen.dart` (CTA carries unit id)
- Update: `lib/l10n/app_bn.arb`, `lib/l10n/app_en.arb` (add_tenant_* keys)

## 15. Notes for the implementing agent
- The "no unit selected" case: if launched from home FAB without a unit, prompt to pick a unit/building first or allow selecting during save. Follow design; keep it simple.
