---
id: T-012
epic: EPIC-07
title: Flutter verify-payment screen
layer: mobile
size: M
status: done
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
- [x] verify_payment_screen matches design
- [x] proof viewer (txn/screenshot)
- [x] verify → receipt; reject + reason
- [x] states; route; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- verify_payment_test → verify→receipt; reject flow
### Manual QA
1. Tenant submits proof → landlord verifies → receipt.

## 13. Acceptance criteria
- [x] Verify screen matches design; verify/reject work.
- [x] **Screen `verifyPay` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens; screenshot via signed URL
### Deviations from spec
- The rent detail endpoint (T-007 `RentRequestSerializer`) does not surface the
  tenant name or the submitted `PaymentProof`. Rather than block on a backend
  change, the screen consumes the proof + tenant name via a typed router `extra`
  payload (`VerifyPaymentArgs`) that the queue (T-013, which already loads the
  list) can supply; when absent the proof viewer shows a "no proof yet"
  placeholder. The signed-URL contract (§15) is honoured: `PaymentProof.photoRef`
  is treated as the signed URL and loaded with `Image.network` (never raw bytes).
- Verify reuses the committed T-010 `rentRequestControllerProvider` as the single
  source of truth for both the load and the verify/reject transitions.
### Files touched (actual)
- Add: apps/mobile/lib/features/rent/presentation/screens/verify_payment_screen.dart
- Add: apps/mobile/test/verify_payment_test.dart
- Update: apps/mobile/lib/core/router/app_router.dart (route `/rent/:id/verify`)
- Update: apps/mobile/lib/l10n/app_en.arb, app_bn.arb (verify_* keys)
- Update: documnets/docs/architecture/07_design_map.md (ledger row 17 ticked)

## 15. Notes for the implementing agent
- Screenshot proof fetched via signed URL (not embedded raw).
