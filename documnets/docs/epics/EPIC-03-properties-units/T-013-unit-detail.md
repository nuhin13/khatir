---
id: T-013
epic: EPIC-03
title: Unit detail screen
layer: mobile
size: M
status: todo
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
- [ ] unit_detail_screen matches design
- [ ] editable rent/status/type/amenities (PATCH)
- [ ] add-tenant CTA (placeholder route)
- [ ] tenant/lease placeholder region (TODO EPIC-06)
- [ ] all states
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- unit_detail_test → renders unit; edit status persists; add-tenant routes
### Manual QA
1. Open unit → change status vacant→occupied → persists.

## 13. Acceptance criteria
- [ ] Unit detail matches design; edits persist; states present.
- [ ] **Screen `unit` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; tenant region marked for EPIC-06
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep the tenant/lease block as a clean empty-state with a `// TODO(EPIC-06)` so leases drop in later without redesign.
