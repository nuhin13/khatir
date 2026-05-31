---
id: T-009
epic: EPIC-05
title: Flutter DMP data layer (repo/models)
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-004, T-005]
blocks: [T-007, T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Flutter DMP data layer (repo/models)

## 1. Feature goal
Typed data layer for DMP: assembled-data model + repo (getDmpData, generatePdf, getRecord).

## 2. Business logic
freezed DmpData + DmpRecord; repo calls the endpoints; providers.

## 3. What this task DOES
- Models + repo + providers + tests (mocked).

## 5. Files & changes
### Add
- features/dmpform/data/{models,dmp_repository,providers}.dart; test

## 6. Database changes
None.
## 7. API changes
Consumes dmpform endpoints.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] DmpData/DmpRecord models
- [ ] repo getDmpData/generatePdf/getRecord
- [ ] providers
- [ ] tests (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_get_dmp_data, test_generate_pdf
### Manual QA
1. Fetch data + generate via repo.

## 13. Acceptance criteria
- [ ] Typed DMP data layer; tests + analyze pass.

## 14. Self-review
- [ ] Masked NID only client-side
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep full NID off the client; only masked in DmpData.
