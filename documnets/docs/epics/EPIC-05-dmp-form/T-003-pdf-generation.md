---
id: T-003
epic: EPIC-05
title: PDF generation (template-accurate)
layer: backend
size: L
status: todo
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-005, T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · PDF generation (template-accurate)

## 1. Feature goal
Render the assembled DMP data into a print-accurate PDF matching the official form layout, with Bangla text support.

## 2. Business logic
Deterministic server-side rendering (reportlab or weasyprint — decide + document). Embed a Bangla-capable font. Field positions match the official template (versioned). Output bytes → stored via encrypted storage by T-005.

## 3. What this task DOES
- `dmpforms/pdf.py`: `render_dmp_pdf(dmp_data, template_version) -> bytes`.
- Bangla font embedding; layout per template; deterministic output. Golden-file-style test (T-010 verifies fidelity).

## 5. Files & changes
### Add
- dmpforms/pdf.py, fonts/, tests/test_pdf.py
### Update
- requirements (reportlab/weasyprint)

## 6. Database changes
None.
## 7. API changes
None (used by T-005).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] choose + document renderer (reportlab/weasyprint)
- [ ] embed Bangla font
- [ ] layout matches template (versioned)
- [ ] deterministic bytes output
- [ ] render Bangla + English fields correctly
- [ ] test (golden/field positions)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_pdf_renders, test_bangla_text_present, test_deterministic
### Manual QA
1. Generate PDF; open in 2 viewers; compare to official form.

## 13. Acceptance criteria
- [ ] Field-accurate, Bangla-capable, deterministic PDF; tests + lint pass.

## 14. Self-review
- [ ] Matches verified template (T-010); fonts embedded
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This is sized L because layout fidelity is exacting. Coordinate with T-010 (template verification) — do not consider "done" until the rendered PDF matches the real DMP form field-by-field.
