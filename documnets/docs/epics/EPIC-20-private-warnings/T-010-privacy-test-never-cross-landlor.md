---
id: T-010
epic: EPIC-20
title: Privacy test (never cross-landlord/public)
layer: cross-cutting
size: S
status: todo
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

# T-010 · Privacy test (never cross-landlord/public)

## 1. Feature goal
Test: landlord A cannot read landlord B's warnings; no endpoint aggregates warnings across landlords; no public read path exists. Hard legal gate.

## 2. Business logic
Test: landlord A cannot read landlord B's warnings; no endpoint aggregates warnings across landlords; no public read path exists. Hard legal gate.

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
- [ ] No cross-landlord/public path possible
### Deviations from spec
### Files touched (actual)
## 15. Notes
Test: landlord A cannot read landlord B's warnings; no endpoint aggregates warnings across landlords; no public read path exists. Hard legal gate.
