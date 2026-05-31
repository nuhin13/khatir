---
id: T-004
epic: EPIC-18
title: Generate + edit + PDF endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, EPIC-05.T-003]
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

# T-004 · Generate + edit + PDF endpoints

## 1. Feature goal
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.

## 2. Business logic
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. No external (beyond gateway). Tier-gated + audited + owner-scoped. 

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] tier gate + audit + owner scope
- [ ] Tests 
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tests + lint pass.
## 14. Self-review
- [ ] Required clauses guaranteed; disclaimer present; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.
