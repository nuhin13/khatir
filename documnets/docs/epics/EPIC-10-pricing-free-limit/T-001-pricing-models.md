---
id: T-001
epic: EPIC-10
title: PricingTier + Subscription models
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-002, T-003, T-004, T-005]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · PricingTier + Subscription models

## 1. Feature goal
Create the `billing` app with PricingTier and Subscription models.

## 2. Business logic
Per schema Domain 7. PricingTier(key unique, label/label_bn, tenant_min/max, monthly_price/annual_price Decimal nullable, includes_verification bool, included_credits int, active bool, sort_order). Subscription(user FK, tier FK, billing_cycle, status, start_at, next_billing_at). BillingCycle/SubscriptionStatus enums.

## 3. What this task DOES
- billing app; both models; enums; admin; migration; factories + tests.

## 5. Files & changes
### Add
- khatir/billing/{__init__,apps,models,enums,admin}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
Creates billing_pricingtier, billing_subscription. Reversible.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] PricingTier (key unique, prices Decimal nullable, includes_verification)
- [ ] Subscription (user/tier FKs, billing_cycle enum, status enum)
- [ ] enums match enums.md
- [ ] admin + migration reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_tier_create, test_subscription_create
## 13. Acceptance criteria
- [ ] Models per schema; migration clean; tests + lint pass.
## 14. Self-review
- [ ] Prices Decimal; key unique; enums correct
### Deviations from spec
### Files touched (actual)
## 15. Notes
- tenant_max null = unlimited. EPIC-12 admin portal manages these records.
