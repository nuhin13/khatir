---
id: T-014
epic: EPIC-19
title: Tenant data isolation test
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

# T-014 · Tenant data isolation test

## 1. Feature goal
Integration test: tenant A cannot read tenant B's lease/rent/receipts via any /me/ endpoint. Hard privacy gate.

## 2. Business logic
Integration test: tenant A cannot read tenant B's lease/rent/receipts via any /me/ endpoint. Hard privacy gate.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Test / seed only. No external. No new flags.

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
- [ ] No cross-tenant access possible
### Deviations from spec
### Files touched (actual)
## 15. Notes
Integration test: tenant A cannot read tenant B's lease/rent/receipts via any /me/ endpoint. Hard privacy gate.
