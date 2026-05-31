---
id: T-002
epic: EPIC-16
title: Enhanced audit-log endpoint (filters + CSV)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-11.T-002]
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

# T-002 · Enhanced audit-log endpoint (filters + CSV)

## 1. Feature goal
Extend the existing /admin/api/audit-log with: full filters (admin_user, action, entity_type, entity_id, date_range) + CSV export stream. Compliance+super.

## 2. Business logic
Extend the existing /admin/api/audit-log with: full filters (admin_user, action, entity_type, entity_id, date_range) + CSV export stream. Compliance+super.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- compliance/views.py, serializers, tests, urls.

## 6–10.
DB: reads/writes as described. Admin audit on process actions. Compliance+super. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Compliance+super role gate
- [ ] Admin audit where applicable
- [ ] Tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per description
## 13. Acceptance criteria
- [ ] Feature works per goal; role-gated; audited; tests + lint pass.
## 14. Self-review
- [ ] Compliance+super; audit on process
### Deviations from spec
### Files touched (actual)
## 15. Notes
Extend the existing /admin/api/audit-log with: full filters (admin_user, action, entity_type, entity_id, date_range) + CSV export stream. Compliance+super.
