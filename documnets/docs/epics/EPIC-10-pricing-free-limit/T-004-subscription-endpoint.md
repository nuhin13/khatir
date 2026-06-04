---
id: T-004
epic: EPIC-10
title: Subscription create/upgrade endpoint
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-007]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Subscription create/upgrade endpoint

## 1. Feature goal
Let a landlord subscribe or upgrade to a tier (payment stubbed for MVP).

## 2. Business logic
POST /billing/subscribe with tier_key. Validates tier active. Creates/updates Subscription. MFS payment is stubbed (records intent; admin can manually confirm). Audited. GET returns current subscription + usage.

## 3. What this task DOES
- Subscribe/upgrade + GET current subscription; audit; tests.

## 5. Files & changes
### Add
- billing/{serializers,services,views,urls}.py; tests/test_subscription_api.py
### Update
- config/urls.py

## 6. Database changes
Writes Subscription.
## 7. API changes
| GET | /api/v1/billing/subscription | Bearer | 200 |
| POST | /api/v1/billing/subscribe | Bearer | 201 |

## 8. UI changes
No UI.
## 9. External services
MFS (stubbed).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] GET current subscription + usage (tenants_used/limit)
- [ ] POST subscribe/upgrade (validate tier, create/update subscription)
- [ ] MFS payment stubbed (records intent)
- [ ] audit
- [ ] Tests: subscribe, upgrade, inactive tier rejected
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_subscribe, test_upgrade, test_inactive_tier_rejected
### Manual QA
1. Subscribe to bundle_10 → subscription active.

## 13. Acceptance criteria
- [ ] Subscription endpoints work; payment stubbed; audited; tests + lint pass.
## 14. Self-review
- [ ] Payment stubbed clearly; audit present
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Real MFS integration is a separate task/epic. Keep a clear stub comment so it's easy to wire later.
