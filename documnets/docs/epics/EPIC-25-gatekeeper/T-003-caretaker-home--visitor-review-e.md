---
id: T-003
epic: EPIC-25
title: Caretaker home + visitor review endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: [gatekeeper_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Caretaker home + visitor review endpoints

## 1. Feature goal
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.

## 2. Business logic
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/gatekeeper/... ; tests.

## 6–10.
DB: as described. Caretaker-scoped to assigned buildings. Audited. No external. Flag gatekeeper_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Caretaker scope (assigned buildings only) where applicable
- [ ] Audit on writes
- [ ] Tests: happy + scoping
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [ ] Feature works per goal; scoped; audited; tests + lint pass.
## 14. Self-review
- [ ] Assigned-buildings scope; photo encrypted; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.
