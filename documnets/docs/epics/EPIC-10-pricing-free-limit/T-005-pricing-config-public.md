---
id: T-005
epic: EPIC-10
title: Pricing tiers + subscription state in /config/public
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Pricing tiers + subscription state in /config/public

## 1. Feature goal
Expose the active tiers list and the current user's subscription/usage in /config/public so the app can show plan info and enforce limits client-side.

## 2. Business logic
/config/public (authenticated) → adds subscription{tier_key, status, tenants_used, tenant_limit, can_verify_nid} + tiers list. Unauthenticated → tiers list only (for marketing if needed).

## 3. What this task DOES
- Update /config/public view; serializers; tests.

## 5. Files & changes
### Update
- config/public view + serializers
### Add
- tests

## 6. Database changes
None.
## 7. API changes
/config/public gains pricing.tiers + subscription block (when authenticated).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tiers list in /config/public (all active)
- [ ] subscription block (authenticated: tier, status, usage, can_verify_nid)
- [ ] Tests: tiers present, subscription block for auth user
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_config_public_tiers, test_config_public_subscription_auth
### Manual QA
1. GET /config/public (auth) → subscription block present.

## 13. Acceptance criteria
- [ ] Tiers + subscription in /config/public; tests + lint pass.
## 14. Self-review
- [ ] No sensitive billing data exposed
### Deviations from spec
### Files touched (actual)
## 15. Notes
- can_verify_nid = subscription.tier.includes_verification.
