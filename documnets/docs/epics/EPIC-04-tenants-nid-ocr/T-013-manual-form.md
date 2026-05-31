---
id: T-013
epic: EPIC-04
title: Flutter manual tenant form
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-009]
blocks: [T-016]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-013 · Flutter manual tenant form

## 1. Feature goal
A plain manual-entry form for tenant details (the fallback when OCR/voice aren't used), including family members, leading to save → DMP.

## 2. Business logic
Per `manualTenant` design. All DMP-required fields entered by hand; family sub-form (T-015); validation; save → DMP.

## 3. What this task DOES
- Manual form screen (name, NID, DOB, address, phone, etc. per DMP needs) + family sub-form + validation + proceed. Widget test.

## 5. Files & changes
### Add
- features/tenants/presentation/screens/manual_tenant_screen.dart; ARB; test
### Update
- routing /tenants/add/manual

## 6. Database changes
None.
## 7. API changes
None directly (save T-016).

## 8. UI changes
- **Design source:** screen `manualTenant` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('manualTenant')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/add/manual`
- Translate manual form; values from packages/design-tokens
- States: data, validation errors
- Navigation: proceed → save+DMP (T-016)
- i18n keys: `manual_title`, plus shared `tenant_*` field keys (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] manual form (all DMP-required fields)
- [ ] family sub-form (T-015)
- [ ] validation
- [ ] proceed → save (T-016)
- [ ] route /tenants/add/manual
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- manual_tenant_test → validation; proceed calls save
### Manual QA
1. Fill form → save → tenant created.

## 13. Acceptance criteria
- [ ] Manual form per design; validation; saves.
- [ ] **Screen `manualTenant` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Shares field widgets + family sub-form with OCR review; tokens used
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse the same field widgets + family sub-form as the OCR review (T-011/T-015) — manual is just the same form with no prefill.
