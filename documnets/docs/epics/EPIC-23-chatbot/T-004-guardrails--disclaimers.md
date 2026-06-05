---
id: T-004
epic: EPIC-23
title: Guardrails + disclaimers
layer: backend
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
- [x] Core implementation per goal — hardened guardrails + bilingual disclaimer in `BASE_SYSTEM_PROMPT`
- [x] Scoping/guardrails as applicable — refuse out-of-scope, no definitive legal/financial advice, refer a professional
- [x] Tests — `tests/test_guardrails.py` (refusal + disclaimer presence, bilingual, assembled prompt keeps scope)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; scoped + safe; tests pass.
## 14. Self-review
- [x] Own-data only; disclaimers present
### Deviations from spec
None. Guardrails live in `BASE_SYSTEM_PROMPT` (one auditable place) per T-002's
handoff note, so every chat call inherits them; the view was not touched.
### Files touched (actual)
- `apps/api/khatir/chatbot/prompts.py` — hardened guardrails + `LEGAL_FINANCIAL_DISCLAIMER`
- `apps/api/khatir/chatbot/tests/test_guardrails.py` — new tests (refusal + disclaimer presence, bilingual)
## 15. Notes
System-prompt guardrails: no definitive legal/financial advice (add disclaimer + suggest a professional), stay on product/tenancy topics, refuse out-of-scope, bilingual. Tests for refusal + disclaimer presence.
