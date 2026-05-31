---
id: T-005
epic: EPIC-16
title: Seed compliance config (SLA days)
layer: backend
size: XS
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
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

# T-005 · Seed compliance config (SLA days)

## 1. Feature goal
Seed data_request_sla_days (int, default 30), data_delete_grace_days (int, default 7).

## 2. Business logic
Seed data_request_sla_days (int, default 30), data_delete_grace_days (int, default 7).

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
Seed data_request_sla_days (int, default 30), data_delete_grace_days (int, default 7).
