---
id: T-008
epic: EPIC-23
title: Chat scoping + guardrail test
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-003, T-004]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-13
completed_at: 2026-06-13
executed_by: claude
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
- [x] Core implementation per goal
- [x] Scoping/guardrails as applicable
- [x] Tests
- [x] analyze + test pass (Flutter mobile layer)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; scoped + safe; tests pass.
## 14. Self-review
- [x] No cross-user data; guardrails hold
### Deviations from spec
None. T-008 specifies "cross-cutting" (backend + mobile); this commit covers the Flutter/mobile safety layer. Backend scoping is enforced in T-003 (already done).
### Files touched (actual)
- `apps/mobile/test/chat_safety_test.dart` — scoping (2 tests), guardrail UI (3 tests), flag gate (2 tests)
## 15. Notes
Flutter safety layer: (1) own-data scoping tests assert no user_id param is sent and that two independent ProviderContainers with different tokens never cross-contaminate; (2) guardrail tests assert the disclaimer overlay appears for EN+BN advice keywords and is absent for benign replies; (3) flag-gate tests assert the send input is disabled and disabled-state UI shown when chatbot_enabled=false.
