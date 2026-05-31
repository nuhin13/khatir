---
id: T-010
epic: EPIC-21
title: Kill-switch + consent enforcement test
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-002, T-003]
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

# T-010 · Kill-switch + consent enforcement test

## 1. Feature goal
Test: reviews_feature off → all review endpoints 403; visibility beyond the pair requires a logged ConsentRecord; default deny holds.

## 2. Business logic
Test: reviews_feature off → all review endpoints 403; visibility beyond the pair requires a logged ConsentRecord; default deny holds.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Cross-cutting compliance test. No external. No new flags (uses reviews_feature).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Tests
- [ ] ruff + mypy clean

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
Test: reviews_feature off → all review endpoints 403; visibility beyond the pair requires a logged ConsentRecord; default deny holds.
