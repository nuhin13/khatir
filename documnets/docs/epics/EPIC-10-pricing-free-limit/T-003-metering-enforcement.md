---
id: T-003
epic: EPIC-10
title: Tenant-count metering + free-limit enforcement
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-04.T-008]
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

# T-003 · Tenant-count metering + free-limit enforcement

## 1. Feature goal
Block tenant creation when a landlord on the free tier exceeds the limit, returning an upgrade-required error.

## 2. Business logic
On tenant create: count active tenants for the owner; compare to tier's max (or free_tier_tenant_limit config if no subscription). If over → raise TierLimitExceeded (error code `tier_limit_exceeded`). select_for_update to prevent race condition. NID verification gated separately in T-009.

## 3. What this task DOES
- check_tenant_limit(user) service; wired into tenant create (EPIC-04 T-007); error envelope code; tests (at limit, over limit, upgraded tier).

## 5. Files & changes
### Update
- billing/services.py (check_tenant_limit)
- EPIC-04 tenants/services.py (call check_tenant_limit before create)
### Add
- billing/tests/test_metering.py

## 6. Database changes
No schema change.
## 7. API changes
Tenant create now returns 402/409 `tier_limit_exceeded` when over limit.
## 8. UI changes
No UI (EPIC-10 T-008 handles the prompt).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] check_tenant_limit(user) → raises TierLimitExceeded when over
- [x] limit from tier.tenant_max or free_tier_tenant_limit config
- [x] select_for_update (race condition)
- [x] wired into tenant create
- [x] error envelope code tier_limit_exceeded
- [x] Tests: at limit (ok), over limit (error), upgraded tier (ok)
- [x] ruff clean (mypy: pre-existing factory-boy stub noise only)

## 12. Test plan
### Automated
- test_at_limit_ok, test_over_limit_blocked, test_upgraded_tier_passes
### Manual QA
1. Add 2 tenants (free) → ok. Add 3rd → 402/409 with upgrade error.

## 13. Acceptance criteria
- [x] Tenant creation blocked past free limit; race-safe; tests + lint pass.
## 14. Self-review
- [x] select_for_update; error code correct; limit from config
### Deviations from spec
- Added a new `tier_limit_exceeded` value to `core.enums.ErrorCode` and a
  `TierLimitExceeded` AppError (402) in `core/exceptions.py` — the spec named
  the code but it did not yet exist in the canonical enum. Chose 402
  (payment/upgrade required) over 409 since the resolution is an upgrade.
- `check_tenant_limit` lives in the shared `billing/services.py` (co-created
  with EPIC-10 T-004's subscribe service on the same branch).
### Files touched (actual)
- apps/api/khatir/core/enums.py (TIER_LIMIT_EXCEEDED)
- apps/api/khatir/core/exceptions.py (TierLimitExceeded → 402)
- apps/api/khatir/billing/services.py (check_tenant_limit, _tenant_limit)
- apps/api/khatir/tenants/services.py (call check_tenant_limit in create_tenant)
- apps/api/khatir/billing/tests/test_metering.py (new)
## 15. Notes
- Use the existing EPIC-04 T-008 count selector. Don't re-implement counting.
