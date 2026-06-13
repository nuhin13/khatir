---
id: T-006
epic: EPIC-23
title: Flutter chat sheet UI
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
blocks: []
external_services: []
feature_flags: [chatbot_enabled]
started_at: 2026-06-13
completed_at: 2026-06-13
executed_by: claude
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
- `apps/mobile/lib/features/chat/presentation/widgets/chat_sheet.dart` — ChatSheet, showChatSheet, all sub-widgets
- `apps/mobile/lib/l10n/app_en.arb` + `app_bn.arb` — 10 new bilingual keys
- `apps/mobile/lib/l10n/app_localizations.dart` + `_en.dart` + `_bn.dart` — generated getters
- `apps/mobile/test/chat_sheet_test.dart` — widget tests
## 15. Notes
A reusable chat bottom-sheet/overlay reachable from any screen via `showChatSheet(context)`. Message list, streaming dots, bilingual disclaimers, guardrail overlay, chatbot_enabled flag gate. All values from design tokens.
