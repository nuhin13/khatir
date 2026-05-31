---
id: T-002
epic: EPIC-19
title: Tenant self-service endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-06.T-004, EPIC-07.T-001]
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

# T-002 · Tenant self-service endpoints

## 1. Feature goal
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.

## 2. Business logic
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.

## 3. What this task DOES
See feature goal. Reuses existing pipelines (EPIC-07/08) — does NOT duplicate logic.

## 5. Files & changes
### Add/Update
- tenants/me_views.py or per-domain /me endpoints; tests.

## 6–10.
DB: reads/writes via existing models. Tenant-scoped. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core endpoint per goal
- [ ] tenant_for_user scoping (own only)
- [ ] reuse existing pipeline (no duplication)
- [ ] Tests: works + scoped + others' blocked
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [ ] Endpoint works, tenant-scoped, reuses pipeline; tests + lint pass.
## 14. Self-review
- [ ] No duplicated proof/maintenance logic; strict scope
### Deviations from spec
### Files touched (actual)
## 15. Notes
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.
