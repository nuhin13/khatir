---
id: T-010
epic: EPIC-08
title: Flutter maintenance queue + resolve
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
- [ ] queue list (open requests, photo via signed URL)
- [ ] resolve-with-cost → auto-expense
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- maintenance_queue_test → list; resolve creates expense
### Manual QA
1. Tenant submits (web) → landlord resolves with cost → expense appears.

## 13. Acceptance criteria
- [ ] Maintenance queue + resolve→expense; states; tests + analyze pass.

## 14. Self-review
- [ ] Resolve creates one expense; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- The prototype shows maintenance within expenses/unit context — follow the design's placement.
