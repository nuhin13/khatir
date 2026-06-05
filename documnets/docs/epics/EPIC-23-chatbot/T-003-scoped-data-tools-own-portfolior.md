---
id: T-003
epic: EPIC-23
title: Scoped data tools (own portfolio/rent summary)
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [T-002, EPIC-09.T-001]
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

# T-003 · Scoped data tools (own portfolio/rent summary)

## 1. Feature goal
A small set of read-only, request.user-scoped lookups the bot can use to answer data questions (collection this month, occupancy, overdue count) — reusing EPIC-09 selectors. STRICTLY own-data only; never accepts a user id parameter.

## 2. Business logic
A small set of read-only, request.user-scoped lookups the bot can use to answer data questions (collection this month, occupancy, overdue count) — reusing EPIC-09 selectors. STRICTLY own-data only; never accepts a user id parameter.

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
- [ ] STRICT own-data scope (no user-id param)
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
A small set of read-only, request.user-scoped lookups the bot can use to answer data questions (collection this month, occupancy, overdue count) — reusing EPIC-09 selectors. STRICTLY own-data only; never accepts a user id parameter.
