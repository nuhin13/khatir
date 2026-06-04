---
id: T-015
epic: EPIC-04
title: Family-members sub-form (shared)
layer: mobile
size: S
status: done
preferred_agent: codex
depends_on: [T-014]
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

# T-015 · Family-members sub-form (shared)

## 1. Feature goal
A reusable widget to add/edit/remove family members (name + relation), embedded in OCR review, voice review, and manual forms.

## 2. Business logic
List of {name, relation}; add/remove rows; used by all three add-tenant paths so family capture is consistent and feeds the DMP form.

## 3. What this task DOES
- `features/tenants/presentation/widgets/family_members_field.dart` (dynamic list). Widget test.

## 5. Files & changes
### Add
- family_members_field.dart; ARB; test
### Update
- referenced by T-011/012/013

## 6. Database changes
None.
## 7. API changes
None (part of tenant create payload).
## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Component: FamilyMembersField (used in ocr/voice/manual)
- States: data (dynamic rows), empty
- i18n keys: `family_add`, `family_name`, `family_relation`, `family_remove` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] dynamic add/remove rows (name + relation)
- [x] used by ocr/voice/manual forms
- [x] ARB bn + en
- [x] widget test (add/remove)
- [x] analyze + test pass

## 12. Test plan
### Automated
- family_field_test → add row, edit, remove
### Manual QA
1. Add 2 family members → save → present on tenant.

## 13. Acceptance criteria
- [x] Reusable family sub-form; used by all 3 paths; tests pass.

## 14. Self-review
- [x] Single shared widget (no duplication)
### Deviations from spec
- New canonical i18n keys `family_add/family_name/family_relation/family_remove` (bn template + en) per §8; the older inline `ocr_family_*` keys remain for the OCR section heading but the shared widget now uses the `family_*` keys (identical values).
- Voice path uses the shared widget transitively: the voice screen (T-012) navigates to the OCR review screen, which embeds `FamilyMembersField`. No separate voice form exists.
### Files touched (actual)
- Add: `lib/features/tenants/presentation/widgets/family_members_field.dart`; `test/family_members_field_test.dart`; ARB `family_*` keys in `lib/l10n/app_bn.arb` + `lib/l10n/app_en.arb`.
- Update: `ocr_review_screen.dart` + `manual_tenant_screen.dart` now embed the shared widget (removed their duplicated `_FamilyDraftRow`/`_FamilyRow`/`_AddFamilyButton`).

## 15. Notes for the implementing agent
- Relation can be a free text or a small enum (spouse/child/parent/other) — follow design; keep it simple.
