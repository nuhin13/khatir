---
id: T-004
epic: EPIC-16
title: Data request queue endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-002]
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

# T-004 · Data request queue endpoints

## 1. Feature goal
GET /admin/api/data-requests (filterable by status/type/sla). POST /{id}/process (approve: generate export package or queue delete + audit; or reject + reason). SLA due from config. Compliance+super.

## 2. Business logic
GET /admin/api/data-requests (filterable by status/type/sla). POST /{id}/process (approve: generate export package or queue delete + audit; or reject + reason). SLA due from config. Compliance+super.

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
GET /admin/api/data-requests (filterable by status/type/sla). POST /{id}/process (approve: generate export package or queue delete + audit; or reject + reason). SLA due from config. Compliance+super.
