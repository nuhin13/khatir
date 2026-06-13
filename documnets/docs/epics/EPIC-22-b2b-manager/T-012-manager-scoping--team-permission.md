---
id: T-012
epic: EPIC-22
title: Manager scoping + team permission test
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-001, T-002]
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

# T-012 · Manager scoping + team permission test

## 1. Feature goal
Test: a manager sees only active-linked owners' data (not pending/revoked/other managers'); team members respect their permission scope. Hard scoping gate.

## 2. Business logic
Test: a manager sees only active-linked owners' data (not pending/revoked/other managers'); team members respect their permission scope. Hard scoping gate.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Cross-cutting scoping test. No external. No new flags.

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
- [ ] No cross-owner bleed; team perms enforced
### Deviations from spec
### Files touched (actual)
## 15. Notes
Test: a manager sees only active-linked owners' data (not pending/revoked/other managers'); team members respect their permission scope. Hard scoping gate.
