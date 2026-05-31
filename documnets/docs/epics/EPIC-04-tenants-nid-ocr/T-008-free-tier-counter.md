---
id: T-008
epic: EPIC-04
title: Free-tier counter hook (count tenants)
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Free-tier counter hook (count tenants)

## 1. Feature goal
Expose the landlord's current tenant count + free-limit status so the UI can show "1/2 free" and EPIC-10 can enforce the limit.

## 2. Business logic
Free limit from `free_tier_tenant_limit` SystemConfig (default 2). This task provides the count + a soft signal; hard enforcement (blocking creation / requiring upgrade) is EPIC-10.

## 3. What this task DOES
- A selector / endpoint field: tenants_used, free_limit, is_over_free.
- Surface in profile/me or a small `/api/v1/usage` endpoint. Tests on counting.

## 5. Files & changes
### Add
- usage selector + tests
### Update
- expose in /usage or /auth/me

## 6. Database changes
None (count query).
## 7. API changes
Adds usage fields (tenants_used, free_limit, is_over_free).
## 8. UI changes
No UI (consumed by More/plan + EPIC-10).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] tenant count selector (per owner, non-deleted)
- [ ] free_limit from SystemConfig
- [ ] is_over_free signal
- [ ] exposed (usage endpoint or me)
- [ ] Tests: count, limit, over-flag
- [ ] ruff clean

## 12. Test plan
### Automated
- test_count, test_over_free_when_exceeds
### Manual QA
1. Add 3rd tenant → is_over_free true (not blocked yet).

## 13. Acceptance criteria
- [ ] Accurate count + free status exposed; tests pass.

## 14. Self-review
- [ ] Limit from config not hardcoded
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Do NOT block creation here — EPIC-10 owns enforcement. This is the counter only.
