---
id: T-009
epic: EPIC-21
title: No public reputation architecture test
layer: cross-cutting
size: M
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

# T-009 · No public reputation architecture test

## 1. Feature goal
The critical legal test: assert NO endpoint anywhere returns reviews about a person across leases, to non-parties, or in any public/searchable/aggregate form. Enumerate the review routes and prove none expose a reputation database. This test is a hard compliance gate.

## 2. Business logic
The critical legal test: assert NO endpoint anywhere returns reviews about a person across leases, to non-parties, or in any public/searchable/aggregate form. Enumerate the review routes and prove none expose a reputation database. This test is a hard compliance gate.

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
- [ ] Proved no public/aggregate reputation path exists
### Deviations from spec
### Files touched (actual)
## 15. Notes
The critical legal test: assert NO endpoint anywhere returns reviews about a person across leases, to non-parties, or in any public/searchable/aggregate form. Enumerate the review routes and prove none expose a reputation database. This test is a hard compliance gate.
