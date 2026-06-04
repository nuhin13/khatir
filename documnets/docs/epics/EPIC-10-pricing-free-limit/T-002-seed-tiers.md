---
id: T-002
epic: EPIC-10
title: Seed 6 default pricing tiers
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-003, T-005]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Seed 6 default pricing tiers

## 1. Feature goal
Seed the 6 default tiers so the app has pricing data from day one.

## 2. Business logic
Tiers: free (0-2 tenants, ৳0, no verification), per_tenant (3+ tenants, per-tenant billing), bundle_10, bundle_20, bundle_50, unlimited. Prices are illustrative defaults — admin edits in EPIC-12. Idempotent.

## 3. What this task DOES
- Data migration seeding the 6 PricingTier rows. Reversible (removes them). Tests.

## 5. Files & changes
### Add
- billing/migrations/XXXX_seed_tiers.py or management command; tests

## 6. Database changes
6 PricingTier rows. Reversible.
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
- [ ] 6 tiers with correct keys/limits/prices/verification flags
- [ ] idempotent (upsert or skip-if-exists)
- [ ] reversible
- [ ] Tests: 6 tiers present after migration
- [ ] ruff clean

## 12. Test plan
### Automated
- test_6_tiers_seeded
### Manual QA
1. GET /pricing/tiers → 6 tiers.

## 13. Acceptance criteria
- [ ] 6 tiers seeded correctly; idempotent; reversible; test passes.
## 14. Self-review
- [ ] Keys match enums.md; free tier correct
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Free tier: key=free, min=0, max=2, price=0, includes_verification=false. bundle_10 onwards: includes_verification=true. Final prices TBD by founder — use sensible Bangladeshi defaults.
