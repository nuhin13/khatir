---
id: T-010
epic: EPIC-08
title: Flutter maintenance queue + resolve
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Flutter maintenance queue + resolve

## 1. Feature goal
Landlord view of open maintenance requests with a resolve-with-cost action (which creates an expense).

## 2. Business logic
List open requests (category, desc, photo, unit); resolve → enter cost + note → status resolved + auto-expense. Photo via signed URL.

## 3. What this task DOES
- maintenance_queue_screen + resolve dialog/screen; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/screens/maintenance_queue_screen.dart; ARB; test
### Update
- router /maintenance

## 6. Database changes
None.
## 7. API changes
Consumes maintenance queue + resolve.

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/maintenance`
- Queue + resolve UI (design: maintenance is part of expenses/unit flows; follow prototype)
- States: loading/error/empty/data
- i18n keys: `maintenance_title`, `maintenance_resolve`, `maintenance_cost`, `maintenance_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] queue list (open requests, photo via signed URL)
- [x] resolve-with-cost → auto-expense
- [x] states; route; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- maintenance_queue_test → list; resolve creates expense
### Manual QA
1. Tenant submits (web) → landlord resolves with cost → expense appears.

## 13. Acceptance criteria
- [x] Maintenance queue + resolve→expense; states; tests + analyze pass.

## 14. Self-review
- [x] Resolve creates one expense; tokens
### Deviations from spec
- The design map has no dedicated maintenance-queue screen key; per §15 the
  prototype shows maintenance inside the `expenses` screen's "New requests"
  block (`proto/screens-landlord2.js` → `reg('expenses')`). The queue screen
  reuses that block's composition (category emoji, unit, description, rose
  category chip, "সমাধান + খরচ" resolve action).
- Resolve is a modal dialog (cost + optional note) rather than a separate
  screen — the prototype's action is inline on the card and the resolve body is
  just two fields, so a dialog matches the design and the data-layer resolve
  call exactly (one expense per resolve, server-side).
- The photo renders from `MaintenanceRequest.photoRef` via `Image.network`
  (the backend serves a signed URL there); a load/error degrades to a neutral
  placeholder. The data layer exposes no separate signed-url action.
### Files touched (actual)
- apps/mobile/lib/features/maintenance/presentation/screens/maintenance_queue_screen.dart (add)
- apps/mobile/lib/core/router/app_router.dart (update: register /maintenance)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (add maintenance_* keys)
- apps/mobile/test/maintenance_queue_test.dart (add)

## 15. Notes for the implementing agent
- The prototype shows maintenance within expenses/unit context — follow the design's placement.
