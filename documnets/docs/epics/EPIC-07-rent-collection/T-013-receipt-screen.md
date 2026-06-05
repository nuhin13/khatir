---
id: T-013
epic: EPIC-07
title: Flutter receipt screen
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
- [x] receipt_screen matches design
- [x] receipt summary + PDF preview/share (reuse EPIC-05 pattern)
- [x] states; route; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- receipt_test → renders; share invoked
### Manual QA
1. After verify → receipt → share to tenant.

## 13. Acceptance criteria
- [x] Receipt screen matches design; share works.
- [x] **Screen `receipt` built** (ledger row).
- [x] EPIC-07 rent loop works end-to-end (request→pay→verify→receipt).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Reuses PDF share pattern; tokens
### Deviations from spec
- The backend exposes no GET receipt endpoint yet and the rent detail endpoint
  does not surface the tenant/unit/method/receipt-no/signed-PDF URL, so those
  contextual receipt fields ride into the screen via a typed router `extra`
  payload (`ReceiptArgs`) — the same convention the T-012 verify screen uses for
  the submitted proof. When a signed PDF URL is supplied, Share/Download act on
  the real PDF (reusing the EPIC-05 T-008 share_plus + printing seam, mirrored as
  `ReceiptSharer`/`receiptSharerProvider`); when absent, Share falls back to a
  plain-text receipt summary. Missing field values degrade to a neutral dash.
### Files touched (actual)
- Add: apps/mobile/lib/features/rent/presentation/screens/receipt_screen.dart
- Add: apps/mobile/lib/features/rent/data/receipt_sharer.dart
- Add: apps/mobile/test/receipt_test.dart
- Update: apps/mobile/lib/features/rent/data/rent_repository.dart (fetchReceiptBytes)
- Update: apps/mobile/lib/features/rent/data/providers.dart (receiptBytesProvider)
- Update: apps/mobile/lib/core/router/app_router.dart (/rent/:id/receipt route)
- Update: apps/mobile/lib/l10n/app_en.arb + app_bn.arb (receipt_* keys)

## 15. Notes for the implementing agent
- Reuse share_plus + pdf preview from EPIC-05 T-008. This is the EPIC-07 validation gate (full rent loop).
