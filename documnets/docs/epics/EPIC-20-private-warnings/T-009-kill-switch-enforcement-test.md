---
id: T-009
epic: EPIC-20
title: Kill-switch enforcement test
layer: cross-cutting
size: S
status: done
preferred_agent: codex
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

# T-009 · Kill-switch enforcement test

## 1. Feature goal
Test: with warnings_feature off, issue + list endpoints return feature_disabled and the mobile CTA is hidden. With on, they work.

## 2. Business logic
Test: with warnings_feature off, issue + list endpoints return feature_disabled and the mobile CTA is hidden. With on, they work.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Cross-cutting test. No external. No new flags (uses warnings_feature).

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
- [ ] Follows conventions; private-only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Test: with warnings_feature off, issue + list endpoints return feature_disabled and the mobile CTA is hidden. With on, they work.
