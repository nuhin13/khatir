---
id: T-010
epic: EPIC-08
title: Flutter maintenance queue + resolve screen
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

# T-010 · Flutter maintenance queue + resolve screen

## 1. Feature goal
The landlord's maintenance queue (open requests with photos) + a resolve action that records the cost (creating an expense).

## 2. Business logic
List open/resolved requests; open a request → view photo/description → Resolve with cost+note → expense created. No dedicated prototype screen (queue derives from the maintenance/expenses area); follow the `expenses`/maintenance visual style.

## 3. What this task DOES
- maintenance_queue_screen + resolve sheet; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/screens/maintenance_queue_screen.dart; ARB; test
### Update
- router /maintenance

## 6. Database changes
None.
## 7. API changes
Consumes maintenance list + resolve.

## 8. UI changes
- **Design source:** maintenance area styled like `expenses` — `docs/design/khatir-ui/proto/screens-landlord2.js` (no dedicated key; reuse expenses visual language)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/maintenance`
- States: loading/error/empty/data
- Navigation: resolve → expense; back
- i18n keys: `maintenance_title`, `maintenance_resolve`, `maintenance_cost`, `maintenance_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] maintenance queue (open/resolved, photos)
- [ ] resolve with cost+note → expense
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- maintenance_queue_test → list; resolve creates expense
### Manual QA
1. Tenant reports (web) → queue shows it → resolve with cost → expense.

## 13. Acceptance criteria
- [ ] Queue + resolve→expense works; states.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Consistent with expenses visual; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This screen isn't a separate prototype key; keep it visually consistent with `expenses`. Photo via signed URL.
