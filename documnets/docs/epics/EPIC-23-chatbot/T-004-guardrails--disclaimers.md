---
id: T-004
epic: EPIC-23
title: Guardrails + disclaimers
layer: backend
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

# T-004 · Guardrails + disclaimers

## 1. Feature goal
System-prompt guardrails: no definitive legal/financial advice (add disclaimer + suggest a professional), stay on product/tenancy topics, refuse out-of-scope, bilingual. Tests for refusal + disclaimer presence.

## 2. Business logic
System-prompt guardrails: no definitive legal/financial advice (add disclaimer + suggest a professional), stay on product/tenancy topics, refuse out-of-scope, bilingual. Tests for refusal + disclaimer presence.

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
- [ ] Own-data only; disclaimers present
### Deviations from spec
### Files touched (actual)
## 15. Notes
System-prompt guardrails: no definitive legal/financial advice (add disclaimer + suggest a professional), stay on product/tenancy topics, refuse out-of-scope, bilingual. Tests for refusal + disclaimer presence.
