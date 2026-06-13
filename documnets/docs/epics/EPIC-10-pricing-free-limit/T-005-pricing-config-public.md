---
id: T-005
epic: EPIC-10
title: Pricing tiers + subscription state in /config/public
layer: backend
size: S
status: done
preferred_agent: codex
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
- [x] tiers list in /config/public (all active) — f93ed5d+
- [x] subscription block (authenticated: tier, status, usage, can_verify_nid)
- [x] Tests: tiers present, subscription block for auth user
- [x] ruff clean (mypy informational; factory-boy stub noise tolerated)

## 12. Test plan
### Automated
- test_config_public_tiers, test_config_public_subscription_auth
### Manual QA
1. GET /config/public (auth) → subscription block present.

## 13. Acceptance criteria
- [x] Tiers + subscription in /config/public; tests + lint pass.
## 14. Self-review
- [x] No sensitive billing data exposed (subscription block is a flat dict of
  tier_key/status/tenants_used/tenant_limit/can_verify_nid — no prices, dates,
  or payment data; test asserts price/date keys absent).
### Deviations from spec
- The `/config/public` view lives in `khatir/health/views.py` (the only place it
  has ever lived in this repo), not a dedicated `config` app — extended in place.
- Public-config selectors placed in a new module `khatir/billing/public_config.py`
  rather than mutating `billing/services.py`, which a sibling task (T-004) was
  editing concurrently on the same branch. Keeps the change self-contained.
- Tiers are exposed unconditionally (auth optional) per §2; the `subscription`
  block is added only for authenticated callers via `request.user.is_authenticated`.
### Files touched (actual)
- Add: `apps/api/khatir/billing/public_config.py`
- Add: `apps/api/khatir/billing/tests/test_config_public.py`
- Update: `apps/api/khatir/health/views.py`
## 15. Notes
- can_verify_nid = active subscription tier's `includes_verification`; with no
  active subscription (free / cancelled / past_due) it is False and the limit
  falls back to the `free_tier_tenant_limit` config (never hardcoded). `status`
  still reflects the most-recent row so the UI can show past_due/cancelled.
- Tier serialization reuses T-004's read-only `TierSerializer` (already excludes
  `active`/`sort_order` and exposes the public plan fields only).
