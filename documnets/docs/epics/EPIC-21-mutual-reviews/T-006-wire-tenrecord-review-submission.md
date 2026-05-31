---
id: T-006
epic: EPIC-21
title: Wire tenRecord review submission (EPIC-19)
layer: mobile
size: S
status: todo
preferred_agent: claude-code
depends_on: [EPIC-19.T-010, T-002]
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

# T-006 · Wire tenRecord review submission (EPIC-19)

## 1. Feature goal
The tenRecord screen (built in EPIC-19 T-010) captures rating + consent. Wire its submission to the EPIC-21 review backend (T-002), respecting the consent toggle. tenRecord = the tenant's private record that can become a consented review.

## 2. Business logic
The tenRecord screen (built in EPIC-19 T-010) captures rating + consent. Wire its submission to the EPIC-21 review backend (T-002), respecting the consent toggle. tenRecord = the tenant's private record that can become a consented review.

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
The tenRecord screen (built in EPIC-19 T-010) captures rating + consent. Wire its submission to the EPIC-21 review backend (T-002), respecting the consent toggle. tenRecord = the tenant's private record that can become a consented review.
