---
id: T-009
epic: EPIC-06
title: Lease section on unit detail (fill EPIC-03 placeholder)
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007, EPIC-03.T-013]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Lease section on unit detail (fill EPIC-03 placeholder)

## 1. Feature goal
Replace the unit-detail tenant/lease placeholder (left by EPIC-03 T-013) with the real active lease + tenant summary + upcoming rent.

## 2. Business logic
On unit detail, show current active lease (tenant name, rent, dates, status) + next due period from schedule + a "create lease" CTA if none. Routes to lease form (T-008) and rent request (EPIC-07).

## 3. What this task DOES
- Lease/tenant section widget on unit detail (uses /units/{id}/lease + schedule); CTA logic; states. Widget test.

## 5. Files & changes
### Add
- features/leases/presentation/widgets/unit_lease_section.dart; test
### Update
- EPIC-03 unit_detail_screen.dart — replace placeholder with this section

## 6. Database changes
None.
## 7. API changes
Consumes /units/{id}/lease + schedule.

## 8. UI changes
- **Design source:** `unit` detail lease region — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('unit')`
- Surface: mobile · **Lane:** 🟢 mobile
- Lease section on `/properties/unit/:id`
- States: loading/empty (no lease → create CTA)/data
- Navigation: create lease → /lease/new; request rent → EPIC-07 (placeholder until then)
- i18n keys: `unit_lease_active`, `unit_next_due`, `unit_create_lease` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] unit_lease_section (active lease + tenant + next due)
- [x] empty → create-lease CTA
- [x] replaces EPIC-03 placeholder (remove TODO marker)
- [x] states; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- unit_lease_section_test → shows lease when present; CTA when none
### Manual QA
1. Unit with active lease shows tenant + next due; without → create CTA.

## 13. Acceptance criteria
- [x] Unit detail shows real lease/tenant; EPIC-03 placeholder removed.
- [x] Test + analyze pass.

## 14. Self-review
- [x] EPIC-03 TODO(EPIC-06) marker removed; tokens
### Deviations from spec
- §8 said the rent-request CTA was a placeholder until EPIC-07; EPIC-07
  T-011 (`RentRequestScreen`, `rentRequest` route) is already committed on this
  branch, so the "Request rent" CTA routes to it directly (`?lease=<id>`)
  rather than to a stub.
- The lease region keeps the EPIC-03 "Tenant & lease" heading and the
  add-tenant CTA (a lease needs a tenant first); only the former empty card was
  swapped for the live `UnitLeaseSection`, per the TODO's "heading + CTA stay".
### Files touched (actual)
- apps/mobile/lib/features/leases/presentation/widgets/unit_lease_section.dart (add)
- apps/mobile/lib/features/properties/presentation/screens/unit_detail_screen.dart (replace placeholder)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (+ regenerated app_localizations*) (unit_lease_* keys)
- apps/mobile/test/unit_lease_section_test.dart (add)
- apps/mobile/test/unit_detail_test.dart (override lease repo; assert lease empty state)

## 15. Notes for the implementing agent
- This closes the EPIC-03→06 seam. Rent-request CTA targets EPIC-07 (placeholder until then).
