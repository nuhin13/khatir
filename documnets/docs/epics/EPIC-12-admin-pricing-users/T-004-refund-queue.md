---
id: T-004
epic: EPIC-12
title: Refund queue endpoints
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [EPIC-10.T-004]
blocks: [T-009]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
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
- [x] refund list (pending)
- [x] process (approve/deny + reason)
- [x] audit
- [x] finance+super role gate
- [x] Tests: list, approve, deny, audit
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_refund_list, test_approve, test_deny, test_audit
## 13. Acceptance criteria
- [x] Refund queue + process; audited; tests + lint pass.
## 14. Self-review
- [x] Reason required; audited; role-gated
### Deviations from spec
- No dedicated PaymentIntent table exists: the EPIC-10 stub records pending
  intents as customer-realm `AuditEntry` rows (`action=subscription.payment_intent`,
  `after.state=pending`). The queue is therefore those unresolved entries; a
  refund decision appends a follow-up `subscription.payment_intent` resolution
  entry (`state=refunded`/`refund_denied`, `resolves=<intent id>`) — audit rows
  stay append-only and processing is idempotent (re-process → 409).
- Routes were added to `admin_portal/admin_urls.py` (the `/admin/api/` app-route
  include) rather than `urls.py` (the `/admin/api/auth/` sub-tree), matching the
  established EPIC-11.T-005 / EPIC-12.T-003 convention for application endpoints.
### Files touched (actual)
- Add: `khatir/admin_portal/refund_views.py`, `khatir/admin_portal/tests/test_refund.py`
- Update: `khatir/admin_portal/admin_urls.py`
## 15. Notes
- Keep this simple for MVP. Real MFS refund API integration is a later task.
