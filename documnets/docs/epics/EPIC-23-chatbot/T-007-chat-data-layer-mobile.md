---
id: T-007
epic: EPIC-23
title: Chat data layer (mobile)
layer: mobile
size: S
status: done
preferred_agent: claude-code
depends_on: [T-002]
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

# T-007 · Chat data layer (mobile)

## 1. Feature goal
freezed ChatMessage model + repo send/history + provider. Tests (mocked).

## 2. Business logic
freezed ChatMessage model + repo send/history + provider. Tests (mocked).

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/chatbot/... or features/chat/... per layer; tests.

## 6–10.
No DB; consumes chat endpoints; mobile 🟢. No external (beyond gateway). Flag: [].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Scoping/guardrails as applicable
- [x] Tests
- [x] analyze + test pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; scoped + safe; tests pass.
## 14. Self-review
- [x] Own-data only; disclaimers present
### Deviations from spec
None.
### Files touched (actual)
- `apps/mobile/lib/features/chat/data/models/chat_message.dart` — added `isStreaming` field
- `apps/mobile/lib/features/chat/data/models/chat_message.freezed.dart` — regenerated with isStreaming
- `apps/mobile/lib/features/chat/data/models/chat_message.g.dart` — isStreaming excluded from wire
- `apps/mobile/lib/features/chat/data/chat_providers.dart` — streaming placeholder, chatHistoryProvider, chatControllerProvider alias
- `apps/mobile/test/chat_data_layer_test.dart` — model, repo, controller tests
## 15. Notes
freezed ChatMessage model + repo send/history + provider. Added isStreaming UI-only field and streaming placeholder flow. Tests (mocked).
