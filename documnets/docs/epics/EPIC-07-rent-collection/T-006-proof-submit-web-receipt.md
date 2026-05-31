---
id: T-006
epic: EPIC-07
title: Proof submit + web receipt page
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-005]
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

# T-006 · Proof submit + web receipt page

## 1. Feature goal
Let the tenant submit payment proof from the web page, and view the receipt once the landlord verifies — both token-scoped, no login.

## 2. Business logic
`POST /r/{token}/proof` accepts txn id / screenshot / note → creates PaymentProof, sets request status proof_submitted. `GET /r/{token}/receipt` shows the receipt once verified. Rate-limited per token. Screenshot stored via encrypted storage.

## 3. What this task DOES
- Proof POST handler + webReceipt page; PaymentProof create; rate-limit; tests (submit, receipt-before/after-verify).

## 5. Files & changes
### Add
- rent/web_views.py (proof + receipt), templates/rent/web_receipt.html; tests/test_web_proof.py
### Update
- urls (/r/<token>/proof, /r/<token>/receipt)

## 6. Database changes
Writes PaymentProof.
## 7. API changes
Public POST /r/{token}/proof, GET /r/{token}/receipt (HTML).
## 8. UI changes
- **Design source:** screen `webReceipt` — `docs/design/khatir-ui/proto/screens-other.js` → `reg('webReceipt')`
- Surface: web-link 🌐 (Django template)
- Routes: `/r/{token}/proof` (POST), `/r/{token}/receipt`
- Translate proof form + receipt view; Notun Din palette CSS
- States: submit success, receipt pending (not verified yet) vs ready
- i18n: bn + en

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] POST proof (txn/screenshot/note) → PaymentProof + status proof_submitted
- [ ] screenshot via encrypted storage
- [ ] webReceipt page (pending vs ready)
- [ ] rate-limit per token
- [ ] Tests: submit, receipt before/after verify
- [ ] ruff clean

## 12. Test plan
### Automated
- test_submit_proof, test_receipt_pending, test_receipt_after_verify, test_rate_limit
### Manual QA
1. Submit proof on the web page → landlord sees it; after verify → receipt shows.

## 13. Acceptance criteria
- [ ] Proof submit + web receipt per design; token-scoped + rate-limited.
- [ ] **Screen `webReceipt` built** (ledger row).
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Token-scoped; rate-limited; screenshot encrypted
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse encrypted storage (EPIC-04 T-003) for screenshots. Receipt PDF generation is T-007; this page links/embeds it once ready.
