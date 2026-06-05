---
id: T-005
epic: EPIC-23
title: Seed chatbot config + flag
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [chatbot_enabled]
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
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
- [x] Core implementation per goal — seed migration adds chatbot_enabled flag (enabled=True) + chatbot_rate_limit_per_hour=60 config in value_json
- [x] Scoping/guardrails as applicable — global flag; idempotent + reversible; test-mode no-op (matches featureflags seed convention)
- [x] Tests — tests/test_seed_chatbot_flag.py (5 tests)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; scoped + safe; tests pass.
## 14. Self-review
- [x] Own-data only; disclaimers present (no user data here — seed only; flag is global)
### Deviations from spec
- chatbot_rate_limit_per_hour is carried in the chatbot_enabled flag's value_json (FeatureFlag's intended config home), not a separate config row — there is no standalone Config model in this codebase. Matches the value_json design used across featureflags.
- Seed auto-run is a no-op under config.settings.test (mirrors featureflags.0002_seed_flags) so it never pollutes flag-endpoint tests that assert an empty table; test_seed_chatbot_flag invokes seed_chatbot_flag directly with schema_editor=None.
### Files touched (actual)
- Add: apps/api/khatir/chatbot/migrations/0002_seed_chatbot_flag.py
- Add: apps/api/khatir/chatbot/tests/test_seed_chatbot_flag.py
## 15. Notes
Seed chatbot_enabled flag (on) + chatbot_rate_limit_per_hour config.
