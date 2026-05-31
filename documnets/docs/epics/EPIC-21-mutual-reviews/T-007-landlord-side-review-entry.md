---
id: T-007
epic: EPIC-21
title: Landlord-side review entry
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002]
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

# T-007 · Landlord-side review entry

## 1. Feature goal
Landlord can privately review a tenant after the lease (rating + comment) — mirror of the tenant side, same double-blind + kill-switch + disclaimer. Entry from lease/tenant detail.

## 2. Business logic
Landlord can privately review a tenant after the lease (rating + comment) — mirror of the tenant side, same double-blind + kill-switch + disclaimer. Entry from lease/tenant detail.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No DB; consumes review endpoints; mobile 🟢. No external. No new flags (uses reviews_feature).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Tests
- [ ] analyze + test pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tests pass.
## 14. Self-review
- [ ] Private + consent-gated; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
Landlord can privately review a tenant after the lease (rating + comment) — mirror of the tenant side, same double-blind + kill-switch + disclaimer. Entry from lease/tenant detail.
