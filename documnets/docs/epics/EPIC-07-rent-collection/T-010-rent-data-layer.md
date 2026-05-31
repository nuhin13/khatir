---
id: T-010
epic: EPIC-07
title: Flutter rent data layer
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, T-007]
blocks: [T-011, T-012, T-013, T-014]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Flutter rent data layer

## 1. Feature goal
Typed data layer for rent requests/proofs/payments (models, repo, providers).

## 2. Business logic
freezed RentRequest/PaymentProof/Payment; repo createRequest, queue, verify, reject, markReceived, getReceipt; providers.

## 3. What this task DOES
- Models + repo + providers + tests (mocked).

## 5. Files & changes
### Add
- features/rent/data/{models,rent_repository,providers}.dart; test

## 6. Database changes
None.
## 7. API changes
Consumes rent endpoints.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] freezed models
- [ ] repo create/queue/verify/reject/markReceived/receipt
- [ ] providers
- [ ] tests (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_rent_repo
### Manual QA
1. Create + verify via repo.

## 13. Acceptance criteria
- [ ] Typed rent data layer; tests + analyze pass.

## 14. Self-review
- [ ] Wire schema matches backend
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Enums per enums.md (RentRequestStatus etc.).
