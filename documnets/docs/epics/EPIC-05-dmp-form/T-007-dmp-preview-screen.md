---
id: T-007
epic: EPIC-05
title: Flutter DMP form preview screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-04.T-014, T-004]
blocks: [T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Flutter DMP form preview screen

## 1. Feature goal
Show the assembled DMP form data (masked NID) for the landlord to review before generating the PDF.

## 2. Business logic
Per `dmp` design. Loads /tenants/{id}/dmpform; shows all fields grouped as on the form; "Generate PDF" button → PDF screen (T-008). Minor corrections route back to edit tenant (EPIC-04).

## 3. What this task DOES
- `features/dmpform/presentation/screens/dmp_preview_screen.dart` matching `dmp`; generate button; states. Widget test.

## 5. Files & changes
### Add
- dmp_preview_screen.dart; ARB; test
### Update
- router /dmpform/:tenantId; EPIC-04 save now routes here for real

## 6. Database changes
None.
## 7. API changes
Consumes GET /tenants/{id}/dmpform.

## 8. UI changes
- **Design source:** screen `dmp` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('dmp')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/dmpform/:tenantId`
- Translate form preview layout; values from packages/design-tokens
- States: loading/error/data
- Navigation: generate → PDF screen (T-008); edit → back to tenant
- i18n keys: `dmp_title`, `dmp_generate`, `dmp_edit`, field labels (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] dmp_preview_screen matches design
- [ ] loads + displays assembled data (masked NID)
- [ ] generate → PDF screen
- [ ] edit → tenant
- [ ] states; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- dmp_preview_test → renders fields; generate navigates
### Manual QA
1. Add tenant → DMP preview shows data → generate.

## 13. Acceptance criteria
- [ ] Preview matches design; generate flows to PDF.
- [ ] **Screen `dmp` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Masked NID only; matches design; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This closes the EPIC-04→05 seam: EPIC-04 T-016 now routes here for real (remove its placeholder).
