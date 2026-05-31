---
id: T-011
epic: EPIC-04
title: Flutter OCR review/edit screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-010]
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

# T-011 · Flutter OCR review/edit screen

## 1. Feature goal
Show OCR-extracted fields for the landlord to verify/correct before saving — name, NID number, DOB, address — plus family members, then proceed to save.

## 2. Business logic
Per `ocr` design (review stage). Every field editable (OCR is never trusted blindly). Family sub-form (T-015). Photo_ref carried through. Proceed → save (T-016) → DMP.

## 3. What this task DOES
- Editable field form prefilled from OCR result; family sub-form; validation; proceed button. Widget test.

## 5. Files & changes
### Add
- features/tenants/presentation/screens/ocr_review_screen.dart; ARB; test
### Update
- ocr flow routing

## 6. Database changes
None.
## 7. API changes
None directly (save is T-016).

## 8. UI changes
- **Design source:** screen `ocr` (review/edit stage) — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('ocr')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/add/ocr/review`
- Translate editable field review + family; values from packages/design-tokens
- States: data (prefilled), validation errors
- Navigation: proceed → save+DMP (T-016)
- i18n keys: `ocr_review_title`, `tenant_name`, `tenant_nid`, `tenant_dob`, `tenant_address`, `ocr_confirm` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] editable fields prefilled from OCR
- [ ] family sub-form (T-015)
- [ ] validation (name + NID required)
- [ ] proceed → save flow (T-016)
- [ ] route /tenants/add/ocr/review
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- ocr_review_test → fields editable; validation; proceed calls save
### Manual QA
1. Correct a misread digit → save → tenant has corrected value.

## 13. Acceptance criteria
- [ ] Editable review per design; validation; proceeds to save.
- [ ] **Screen `ocr` fully built** (capture T-010 + review T-011) — ledger row.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] All fields editable; nothing auto-saved unreviewed; tokens used
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- If the provider returns per-field confidence, highlight low-confidence fields for attention. Otherwise treat all as editable normally.
