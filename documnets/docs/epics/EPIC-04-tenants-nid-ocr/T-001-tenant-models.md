---
id: T-001
epic: EPIC-04
title: Tenant + TenantFamilyMember models, enums, migration
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005, EPIC-03.T-001]
blocks: [T-002, T-004, T-007]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Tenant + TenantFamilyMember models, enums, migration

## 1. Feature goal
Create the `tenants` app with `Tenant` and `TenantFamilyMember` models — encrypted NID, masked display, verification status.

## 2. Business logic
Per `06_database_schema.md` Domain 3. `nid_number_enc` (bytea, encrypted), `nid_number_masked` (display), `photo_ref` (encrypted object key), `verification_status` enum default `unverified`, optional `linked_user_id`. Family members CASCADE. Soft-delete + timestamps.

## 3. What this task DOES
- `tenants` app; Tenant + TenantFamilyMember models; `VerificationStatus` enum (enums.md).
- Indexes: `Tenant(nid_number_masked)`.
- Admin (masked display only). Migration. Model tests + factories.

## 4. What this task does NOT do
- No encryption wiring (T-002), no endpoints (T-007).

## 5. Files & changes
### Add
- `khatir/tenants/{__init__,apps,models,enums,admin}.py`, migration, tests/factories
### Update
- settings register `khatir.tenants`

## 6. Database changes
Creates `tenants_tenant`, `tenants_tenantfamilymember`. Reversible.

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
- [x] Tenant model (enc + masked NID, photo_ref, verification_status, linked_user nullable)
- [x] TenantFamilyMember (CASCADE)
- [x] VerificationStatus enum matches enums.md
- [x] Index on nid_number_masked
- [x] Admin masked display
- [x] Migration reversible
- [x] factories + model tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_tenant_create, test_family_member, test_masked_field_present
### Manual QA
1. Create tenant in admin; confirm masked display.

## 13. Acceptance criteria
- [x] Models per schema; migration clean; tests + lint pass.

## 14. Self-review
- [x] Enc + masked columns both present; never plaintext column for NID
### Deviations from spec
- None. `nid_number_enc` is a nullable `BinaryField` (encryption helper lands in
  T-002); `TenantFamilyMember` is `TimeStampedModel` (the schema family table has
  no `deleted_at`), CASCADE from `Tenant`.
### Files touched (actual)
- Add: `khatir/tenants/{__init__,apps,enums,models,admin}.py`,
  `migrations/0001_initial.py`, `tests/{__init__,factories,test_models}.py`
- Update: `config/settings/base.py` (register `khatir.tenants`)

## 15. Notes for the implementing agent
- Do NOT add a plaintext nid_number column. Only enc (bytea) + masked (varchar). Encryption helper wired in T-002.
