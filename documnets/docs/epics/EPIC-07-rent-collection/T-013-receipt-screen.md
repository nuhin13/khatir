---
id: T-013
epic: EPIC-07
title: Flutter receipt screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-010]
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

# T-013 · Flutter receipt screen

## 1. Feature goal
Show the generated rent receipt and let the landlord share it (WhatsApp/system) with the tenant.

## 2. Business logic
Per `receipt` design. Receipt summary (amount, period, date, txn) + PDF preview/share. Reuses PDF preview/share pattern from EPIC-05 T-008.

## 3. What this task DOES
- receipt_screen matching `receipt`; share/download; states. Widget test.

## 5. Files & changes
### Add
- features/rent/presentation/screens/receipt_screen.dart; ARB; test
### Update
- router /rent/:id/receipt

## 6. Database changes
None.
## 7. API changes
Consumes receipt (signed URL).

## 8. UI changes
- **Design source:** screen `receipt` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('receipt')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/rent/:id/receipt`
- Translate receipt summary + share; values from packages/design-tokens
- States: loading/data/error
- Navigation: share (WhatsApp/system); back
- i18n keys: `receipt_title`, `receipt_share`, `receipt_amount`, `receipt_period` (bn + en)

## 9. External services
None (OS share).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] receipt_screen matches design
- [ ] receipt summary + PDF preview/share (reuse EPIC-05 pattern)
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- receipt_test → renders; share invoked
### Manual QA
1. After verify → receipt → share to tenant.

## 13. Acceptance criteria
- [ ] Receipt screen matches design; share works.
- [ ] **Screen `receipt` built** (ledger row).
- [ ] EPIC-07 rent loop works end-to-end (request→pay→verify→receipt).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Reuses PDF share pattern; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse share_plus + pdf preview from EPIC-05 T-008. This is the EPIC-07 validation gate (full rent loop).
