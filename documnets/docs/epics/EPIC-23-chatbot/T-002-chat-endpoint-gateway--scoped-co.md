---
id: T-002
epic: EPIC-23
title: Chat endpoint (gateway + scoped context)
layer: backend
size: M
status: todo
preferred_agent: codex
depends_on: [T-001, EPIC-14.T-007]
blocks: []
external_services: [ai_chat]
feature_flags: [chatbot_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Chat endpoint (gateway + scoped context)

## 1. Feature goal
POST /api/v1/chat: persist user message, build a system prompt + the user's scoped context summary, call AI gateway (chat category), persist + return the reply. Kill-switch gated. Rate-limited per user. GET history.

## 2. Business logic
POST /api/v1/chat: persist user message, build a system prompt + the user's scoped context summary, call AI gateway (chat category), persist + return the reply. Kill-switch gated. Rate-limited per user. GET history.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/chatbot/... or features/chat/... per layer; tests.

## 6–10.
DB as described; backend. External: AI gateway (chat). Flag: [chatbot_enabled].

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
POST /api/v1/chat: persist user message, build a system prompt + the user's scoped context summary, call AI gateway (chat category), persist + return the reply. Kill-switch gated. Rate-limited per user. GET history.
