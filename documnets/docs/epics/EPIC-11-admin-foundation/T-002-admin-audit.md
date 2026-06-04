---
id: T-002
epic: EPIC-11
title: AdminAuditEntry model + audit writer
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-008, T-011]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · AdminAuditEntry model + audit writer

## 1. Feature goal
Every admin action writes an immutable audit record — who, what, before, after, IP, reason.

## 2. Business logic
AdminAuditEntry: admin_user FK, action, entity_type, entity_id, before_json, after_json, ip, reason, created_at. Immutable (no update/delete). Writer: `admin_audit(admin_user, action, entity, before, after, ip, reason)`. All admin endpoints call this.

## 3. What this task DOES
- AdminAuditEntry model; immutable manager (no update/delete methods); audit writer function; migration; tests.

## 5. Files & changes
### Add
- admin_portal/audit.py, migration for AdminAuditEntry; tests/test_audit.py

## 6. Database changes
Creates admin_portal_adminauditentry. Reversible.
## 7. API changes
None (writer only).
## 8. UI changes
No UI (T-011 builds the viewer).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] AdminAuditEntry (FK, action, before/after json, ip, reason)
- [ ] immutable (no update/delete on model manager)
- [ ] admin_audit() writer function
- [ ] migration reversible
- [ ] Tests: write, verify immutable
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_audit_write, test_immutable
### Manual QA
1. Call audit writer → entry created.

## 13. Acceptance criteria
- [ ] Immutable audit model + writer; tests + lint pass.
## 14. Self-review
- [ ] Before/after as JSON diffs; immutable
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- before/after should be diffs, not full objects, where practical. IP from request.META.
