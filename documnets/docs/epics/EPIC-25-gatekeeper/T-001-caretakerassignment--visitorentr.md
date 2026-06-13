---
id: T-001
epic: EPIC-25
title: CaretakerAssignment + VisitorEntry models
layer: backend
size: M
status: done
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
- [x] Core implementation per goal
- [x] Caretaker scope (assigned buildings only) where applicable
- [x] Audit on writes — `visitor.log` action string reserved; writes audited by service/endpoint layer (T-003/T-004); models expose set/get helpers
- [x] Tests: happy + scoping
- [x] ruff clean (gatekeeper app)

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [x] Feature works per goal; scoped; audited; tests + lint pass.
## 14. Self-review
- [x] Assigned-buildings scope; photo encrypted; conventions
### Deviations from spec
- `photo_ref` stored as encrypted `photo_ref_enc` BinaryField (mirrors tenants NID pattern) with `set_photo_ref`/`get_photo_ref` helpers — no plaintext column.
- `CaretakerAssignmentStatus` = active/revoked; scoping treats only `active` assignments as granting visitor-entry visibility.
### Files touched (actual)
- apps/api/khatir/gatekeeper/{__init__,apps,enums,managers,models,admin}.py
- apps/api/khatir/gatekeeper/migrations/{__init__,0001_initial}.py
- apps/api/khatir/gatekeeper/tests/{__init__,factories,test_models,test_scoping}.py
- apps/api/config/settings/base.py (register app)
## 15. Notes
CaretakerAssignment(caretaker User FK, building FK, assigned_by, status). VisitorEntry(building FK, unit FK nullable, visitor_name, purpose, photo_ref nullable encrypted, status pending/approved/denied, logged_by nullable, created_at). Migrations + tests.
