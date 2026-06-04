---
id: T-002
epic: EPIC-05
title: DMP form data assembler (field mapping)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-04.T-002, EPIC-03.T-001]
blocks: [T-003, T-004]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · DMP form data assembler (field mapping)

## 1. Feature goal
Assemble all fields the DMP form needs from tenant + family + building + landlord into one normalized structure, mapping to the official form's fields.

## 2. Business logic
Pulls tenant (full NID via audited decrypt), family members, building (address, area), landlord (name, phone). Maps to the official DMP field set. This is the single place that knows the form's field mapping.

## 3. What this task DOES
- `dmpforms/assembler.py`: `assemble_dmp_data(tenant) -> DmpData` with all official fields. Uses audited NID decrypt. Tests with a full tenant.

## 5. Files & changes
### Add
- dmpforms/assembler.py, dto.py, tests/test_assembler.py

## 6. Database changes
None (reads).
## 7. API changes
None (used by T-003/004).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] assemble_dmp_data maps all official fields
- [ ] full NID via audited decrypt path only
- [ ] family members included
- [ ] building + landlord fields included
- [ ] Tests with complete tenant
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_assemble_all_fields, test_nid_via_audited_path
### Manual QA
1. Assemble for a tenant; inspect all fields populated.

## 13. Acceptance criteria
- [ ] Complete, correct field mapping; NID audited; tests + lint pass.

## 14. Self-review
- [ ] All official fields present; NID access audited + not logged
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- The exact official field list MUST come from the verified template (T-010). If unverified, mark assumptions clearly; T-010 reconciles.
