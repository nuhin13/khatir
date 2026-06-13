---
id: T-011
epic: EPIC-04
title: Flutter OCR review/edit screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-010]
blocks: [T-016]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
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
- [x] editable fields prefilled from OCR
- [x] family sub-form (inline slice ahead of reusable T-015 widget)
- [x] validation (name + NID required)
- [x] proceed → save flow (TenantReviewDraft seam for T-016)
- [x] route /tenants/add/ocr/review
- [x] ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- ocr_review_test → fields editable; validation; proceed calls save
### Manual QA
1. Correct a misread digit → save → tenant has corrected value.

## 13. Acceptance criteria
- [x] Editable review per design; validation; proceeds to save.
- [x] **Screen `ocr` fully built** (capture T-010 + review T-011) — ledger row.
- [x] Test + analyze pass.

## 14. Self-review
- [x] All fields editable; nothing auto-saved unreviewed; tokens used
### Deviations from spec
- T-015 (reusable family sub-form widget) is not a `depends_on` and is not yet
  committed in this worktree, so this task ships a minimal inline family
  sub-form (add/remove name+relation rows) to satisfy §3/§11. T-015 can replace
  it with the shared `family_members_field.dart` widget; the data shape it feeds
  (`FamilyMemberDraft`) is already defined here.
- Proceed cannot reach the real save yet: T-016 (the shared
  `saveTenantAndContinue` action + `/dmpform/:id` route) is not built. The
  proceed button validates then emits a typed `TenantReviewDraft` of the
  *edited* values via an `onProceed` seam (null/no-op by default in the router).
  T-016 wires `onProceed → saveTenantAndContinue`; a TODO marks the router site.
- Low-confidence fields (provider `confidence` ≤ 0.85) are flagged with a butter
  border + a "please check" hint (§15). When confidence is absent the field is a
  normal editable field.
### Files touched (actual)
- apps/mobile/lib/features/tenants/presentation/screens/ocr_review_screen.dart (new)
- apps/mobile/lib/features/tenants/presentation/screens/ocr_review_args.dart (FamilyMemberDraft + TenantReviewDraft)
- apps/mobile/lib/core/router/app_router.dart (real OCR review route)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (ocr_review_*, tenant_*, ocr_family_*, ocr_confirm keys)
- apps/mobile/test/ocr_review_test.dart (new)

## 15. Notes for the implementing agent
- If the provider returns per-field confidence, highlight low-confidence fields for attention. Otherwise treat all as editable normally.
