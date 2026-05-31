---
id: T-006
epic: EPIC-23
title: Flutter chat sheet UI
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002]
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

# T-006 · Flutter chat sheet UI

## 1. Feature goal
A reusable chat bottom-sheet/overlay reachable from the shells: message list, input, streaming reply, disclaimers. Hidden if chatbot_enabled off. Bilingual. Widget test.

## 2. Business logic
A reusable chat bottom-sheet/overlay reachable from the shells: message list, input, streaming reply, disclaimers. Hidden if chatbot_enabled off. Bilingual. Widget test.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/chatbot/... or features/chat/... per layer; tests.

## 6–10.
No DB; consumes chat endpoints; mobile 🟢. No external (beyond gateway). Flag: [chatbot_enabled].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Scoping/guardrails as applicable
- [ ] Tests
- [ ] analyze + test pass

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
A reusable chat bottom-sheet/overlay reachable from the shells: message list, input, streaming reply, disclaimers. Hidden if chatbot_enabled off. Bilingual. Widget test.
