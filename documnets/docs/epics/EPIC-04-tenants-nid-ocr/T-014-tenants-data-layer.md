---
id: T-014
epic: EPIC-04
title: Flutter tenants data layer (repos/models/providers)
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-007]
blocks: [T-011, T-012, T-013, T-015, T-016]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-014 · Flutter tenants data layer (repos/models/providers)

## 1. Feature goal
Typed data layer for tenants: models, repository (OCR/voice/create/list), providers — shared by all add-tenant screens.

## 2. Business logic
freezed Tenant + ExtractedTenant + FamilyMember models; repo methods ocrExtract(image), voiceExtract(audio), createTenant(fields), listUnitTenants. Riverpod providers.

## 3. What this task DOES
- Models + repository + providers + tests (mocked dio).

## 5. Files & changes
### Add
- features/tenants/data/models/*.dart, tenant_repository.dart, tenants_providers.dart, test
### Update
- none

## 6. Database changes
None.
## 7. API changes
Consumes tenants endpoints.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] freezed Tenant/ExtractedTenant/FamilyMember
- [ ] repo: ocrExtract, voiceExtract, createTenant, listUnitTenants
- [ ] providers/controllers
- [ ] Tests (mocked dio)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_ocr_extract, test_create_tenant, test_list_unit_tenants
### Manual QA
1. Create + list tenants for a unit.

## 13. Acceptance criteria
- [ ] Typed tenants data layer; tests + analyze pass.

## 14. Self-review
- [ ] Models match wire schema; masked NID only in list/detail
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Detail/list show masked NID only. The full NID never comes to the client except where a specific permissioned flow needs it (DMP generation happens server-side in EPIC-05, so the client rarely needs full NID).
