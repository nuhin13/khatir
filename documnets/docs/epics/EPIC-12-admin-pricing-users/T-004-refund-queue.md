---
id: T-004
epic: EPIC-12
title: Refund queue endpoints
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [EPIC-10.T-004]
blocks: [T-009]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Refund queue endpoints

## 1. Feature goal
Let finance staff view and process pending refund requests.

## 2. Business logic
GET /admin/api/billing/refunds: pending payment intents from EPIC-10 stub. POST /{id}/process: approve (record processed, update subscription) or deny + reason. Finance+super. Audited.

## 3. What this task DOES
- Refund list + process endpoints; audit; tests.

## 5. Files & changes
### Add
- admin_portal/refund_views.py, tests/test_refund.py
### Update
- admin_portal/urls.py

## 6. Database changes
Updates subscription/payment intent status.
## 7. API changes
| GET | /admin/api/billing/refunds | finance/super | 200 |
| POST | /admin/api/billing/refunds/{id}/process | finance/super | 200 |

## 8. UI changes
No UI (T-009).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] refund list (pending)
- [ ] process (approve/deny + reason)
- [ ] audit
- [ ] finance+super role gate
- [ ] Tests: list, approve, deny, audit
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_refund_list, test_approve, test_deny, test_audit
## 13. Acceptance criteria
- [ ] Refund queue + process; audited; tests + lint pass.
## 14. Self-review
- [ ] Reason required; audited; role-gated
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Keep this simple for MVP. Real MFS refund API integration is a later task.
