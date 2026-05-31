---
id: T-008
epic: EPIC-23
title: Chat scoping + guardrail test
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-003, T-004]
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

# T-008 · Chat scoping + guardrail test

## 1. Feature goal
Test: chat data tools return only request.user's data (no cross-user); guardrails refuse legal/financial advice + out-of-scope. Hard safety gate.

## 2. Business logic
Test: chat data tools return only request.user's data (no cross-user); guardrails refuse legal/financial advice + out-of-scope. Hard safety gate.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/chatbot/... or features/chat/... per layer; tests.

## 6–10.
DB as described; backend. No external (beyond gateway). Flag: [].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Scoping/guardrails as applicable
- [ ] Tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; scoped + safe; tests pass.
## 14. Self-review
- [ ] No cross-user data; guardrails hold
### Deviations from spec
### Files touched (actual)
## 15. Notes
Test: chat data tools return only request.user's data (no cross-user); guardrails refuse legal/financial advice + out-of-scope. Hard safety gate.
