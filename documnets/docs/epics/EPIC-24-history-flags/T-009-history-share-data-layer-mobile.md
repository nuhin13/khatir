---
id: T-009
epic: EPIC-24
title: History-share data layer (mobile)
layer: mobile
size: S
status: todo
preferred_agent: claude-code
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

# T-009 · History-share data layer (mobile)

## 1. Feature goal
freezed HistoryShare model + repo create/list/revoke + provider. Tests (mocked).

## 2. Business logic
freezed HistoryShare model + repo create/list/revoke + provider. Tests (mocked).

## 3. What this task DOES
See feature goal. Built defensively — tenant-controlled, consent-per-share, factual-only, kill-switchable.

## 5. Files & changes
### Add/Update
- khatir/historyshare/... or features/historyshare/... ; tests.

## 6–10.
No DB; consumes history-share endpoints; mobile 🟢. No external. Flag: [].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Tenant-controlled + consent + factual-only as applicable
- [ ] Tests
- [ ] analyze + test pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tenant-controlled + consent-gated + factual-only; tests pass.
## 14. Self-review
- [ ] Tenant initiates; consent logged; factual only; revocable
### Deviations from spec
### Files touched (actual)
## 15. Notes
freezed HistoryShare model + repo create/list/revoke + provider. Tests (mocked).
