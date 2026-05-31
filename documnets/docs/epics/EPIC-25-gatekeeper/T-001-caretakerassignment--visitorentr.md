---
id: T-001
epic: EPIC-25
title: CaretakerAssignment + VisitorEntry models
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-03.T-001]
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

# T-001 · CaretakerAssignment + VisitorEntry models

## 1. Feature goal
CaretakerAssignment(caretaker User FK, building FK, assigned_by, status). VisitorEntry(building FK, unit FK nullable, visitor_name, purpose, photo_ref nullable encrypted, status pending/approved/denied, logged_by nullable, created_at). Migrations + tests.

## 2. Business logic
CaretakerAssignment(caretaker User FK, building FK, assigned_by, status). VisitorEntry(building FK, unit FK nullable, visitor_name, purpose, photo_ref nullable encrypted, status pending/approved/denied, logged_by nullable, created_at). Migrations + tests.

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
CaretakerAssignment(caretaker User FK, building FK, assigned_by, status). VisitorEntry(building FK, unit FK nullable, visitor_name, purpose, photo_ref nullable encrypted, status pending/approved/denied, logged_by nullable, created_at). Migrations + tests.
