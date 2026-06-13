---
id: T-007
epic: EPIC-07
title: Verify / reject / mark-received + receipt PDF
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-05.T-003]
blocks: [T-010]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Verify / reject / mark-received + receipt PDF

## 1. Feature goal
Landlord verifies a submitted proof (or marks cash received), creating a Payment + a receipt PDF; or rejects it.

## 2. Business logic
verify → Payment(verified_by, verified_at) + generate receipt PDF (reuse EPIC-05 PDF/storage pattern) + mark schedule paid + notify tenant. mark-received → same without proof. reject → status rejected + reason. Audit all.

## 3. What this task DOES
- verify/reject/mark-received endpoints; receipt PDF generation (reuse pattern); schedule→paid; notify; audit; tests.

## 5. Files & changes
### Add
- rent/receipts.py (PDF), tests/test_verify.py
### Update
- rent/views.py, urls

## 6. Database changes
Writes Payment; updates schedule status.
## 7. API changes
| POST | /api/v1/rent-requests/{id}/verify | owner | 200 |
| POST | /api/v1/rent-requests/{id}/reject | owner | 200 |
| POST | /api/v1/rent-requests/{id}/mark-received | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None (notify via NotificationSender).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] verify → Payment + receipt PDF + schedule paid + notify
- [ ] mark-received (cash) path
- [ ] reject + reason
- [ ] receipt PDF reuses EPIC-05 generator/storage pattern
- [ ] audit all
- [ ] Tests: verify, mark-received, reject
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_verify_creates_payment_receipt, test_mark_received, test_reject
### Manual QA
1. Verify a proof → receipt generated, schedule paid.

## 13. Acceptance criteria
- [ ] Verify/reject/mark-received + receipt PDF; schedule updates; audited; tests + lint pass.

## 14. Self-review
- [ ] Reuses PDF/storage pattern; notifies tenant; audited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Don't rebuild PDF infra — reuse EPIC-05 T-003 renderer + EPIC-04 T-003 storage. Notify tenant of receipt via NotificationSender (web receipt link).
