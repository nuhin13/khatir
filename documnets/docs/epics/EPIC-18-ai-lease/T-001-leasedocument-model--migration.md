---
id: T-001
epic: EPIC-18
title: LeaseDocument model + migration
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-06.T-001]
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

# T-001 · LeaseDocument model + migration

## 1. Feature goal
LeaseDocument(lease FK, content_json clauses, pdf_ref, generated_by, model_used, generated_at, status draft/final). Migration + admin + tests.

## 2. Business logic
LeaseDocument(lease FK, content_json clauses, pdf_ref, generated_by, model_used, generated_at, status draft/final). Migration + admin + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. No external (beyond gateway).  

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] validation / required-clause guarantee
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
LeaseDocument(lease FK, content_json clauses, pdf_ref, generated_by, model_used, generated_at, status draft/final). Migration + admin + tests.
