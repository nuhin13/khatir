---
id: T-001
epic: EPIC-07
title: RentRequest/PaymentProof/Payment models
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-06.T-001]
blocks: [T-002, T-003, T-007]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · RentRequest/PaymentProof/Payment models

## 1. Feature goal
Create the `rent` app with RentRequest, PaymentProof, Payment models.

## 2. Business logic
Per schema Domain 5. RentRequest(rent_schedule nullable, lease, amount, period, link_token unique, sent_via, sent_at, status). PaymentProof(rent_request, type, value, photo_ref, submitted_at). Payment(rent_request, verified_at, verified_by, receipt_ref). Indexes on link_token + (lease,status).

## 3. What this task DOES
- rent app; 3 models; enums (RentRequestStatus, PaymentProofType, Channel); indexes; admin; migration; tests/factories.

## 5. Files & changes
### Add
- khatir/rent/{__init__,apps,models,enums,admin}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
Creates rent_rentrequest, rent_paymentproof, rent_payment. Reversible.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] RentRequest (link_token unique, status enum, amount Decimal)
- [ ] PaymentProof (type enum, photo_ref)
- [ ] Payment (verified_by, receipt_ref)
- [ ] enums match enums.md
- [ ] indexes (link_token, lease+status)
- [ ] admin + migration reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_models_create, link_token_unique
### Manual QA
1. Create in admin.

## 13. Acceptance criteria
- [ ] Models per schema; migration clean; tests + lint pass.

## 14. Self-review
- [ ] Money Decimal; enums; indexes
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- link_token populated by T-002 service, not here. amount Decimal(12,2).
