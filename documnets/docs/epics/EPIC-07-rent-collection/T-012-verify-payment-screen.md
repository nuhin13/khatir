---
id: T-012
epic: EPIC-07
title: Flutter verify-payment screen
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

# T-012 · Flutter verify-payment screen

## 1. Feature goal
Show submitted payment proofs for the landlord to verify or reject, generating a receipt on verify.

## 2. Business logic
Per `verifyPay` design. Shows proof (txn id / screenshot), amount, tenant; Verify → receipt; Reject → reason. Queue of pending verifications.

## 3. What this task DOES
- verify_payment_screen matching `verifyPay`; verify/reject actions; proof viewer; states. Widget test.

## 5. Files & changes
### Add
- features/rent/presentation/screens/verify_payment_screen.dart; ARB; test
### Update
- router /rent/:id/verify

## 6. Database changes
None.
## 7. API changes
Consumes verify/reject.

## 8. UI changes
- **Design source:** screen `verifyPay` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('verifyPay')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/rent/:id/verify`
- Translate proof review + verify/reject; values from packages/design-tokens
- States: data (proof), verifying, error
- Navigation: verify → receipt; reject → back to queue
- i18n keys: `verify_proof`, `verify_confirm`, `verify_reject`, `verify_reason` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] verify_payment_screen matches design
- [ ] proof viewer (txn/screenshot)
- [ ] verify → receipt; reject + reason
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- verify_payment_test → verify→receipt; reject flow
### Manual QA
1. Tenant submits proof → landlord verifies → receipt.

## 13. Acceptance criteria
- [ ] Verify screen matches design; verify/reject work.
- [ ] **Screen `verifyPay` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; screenshot via signed URL
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Screenshot proof fetched via signed URL (not embedded raw).
