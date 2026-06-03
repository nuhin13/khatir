---
id: T-001
epic: EPIC-05
title: DMPFormRecord model + migration
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-04.T-001]
blocks: [T-005]
external_services: []
feature_flags: []
started_at: 2026-06-04completed_at: 2026-06-04executed_by: claudereviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · DMPFormRecord model + migration

## 1. Feature goal
Persist a record each time a DMP form PDF is generated — which tenant, template version, file ref, when, by whom.

## 2. Business logic
Per schema Domain (platform/forms). Stores pdf_ref (encrypted storage key), template_version, tenant FK, generated_by, generated_at. Audit on generate.

## 3. What this task DOES
- `dmpforms` app + DMPFormRecord model + migration + admin + tests.

## 5. Files & changes
### Add
- khatir/dmpforms/{__init__,apps,models,admin}.py, migration, tests
### Update
- settings register

## 6. Database changes
Creates dmpforms_dmpformrecord. Reversible.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] DMPFormRecord (tenant FK, template_version, pdf_ref, generated_by/at)
- [ ] migration reversible
- [ ] admin + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_record_create
### Manual QA
1. Create record in admin.

## 13. Acceptance criteria
- [ ] Model + migration; tests + lint pass.

## 14. Self-review
- [ ] No raw field payload stored beyond what's needed
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- pdf_ref points into encrypted storage (EPIC-04 T-003). Don't store the full NID here.
