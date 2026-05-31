---
id: T-005
epic: EPIC-23
title: Seed chatbot config + flag
layer: backend
size: XS
status: todo
preferred_agent: codex
depends_on: [EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [chatbot_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Seed chatbot config + flag

## 1. Feature goal
Seed chatbot_enabled flag (on) + chatbot_rate_limit_per_hour config.

## 2. Business logic
Seed chatbot_enabled flag (on) + chatbot_rate_limit_per_hour config.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/chatbot/... or features/chat/... per layer; tests.

## 6–10.
DB as described; backend. No external (beyond gateway). Flag: [chatbot_enabled].

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
- [ ] Own-data only; disclaimers present
### Deviations from spec
### Files touched (actual)
## 15. Notes
Seed chatbot_enabled flag (on) + chatbot_rate_limit_per_hour config.
