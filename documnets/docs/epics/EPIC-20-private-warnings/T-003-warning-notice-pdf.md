---
id: T-003
epic: EPIC-20
title: Warning notice PDF (reuse EPIC-05)
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-002, EPIC-05.T-003]
blocks: [T-006]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Warning notice PDF (reuse EPIC-05)

## 1. Feature goal
Generate a formatted warning-notice PDF (Bangla/English) for a warning, reusing the EPIC-05 PDF infrastructure.

## 2. Business logic
POST /warnings/{id}/notice → render a notice (parties, warning type, reason, date, legal disclaimer) via the EPIC-05 PDF renderer + encrypted storage → signed URL. Owner-scoped + kill-switch.

## 3. What this task DOES
- Notice PDF generation (reuse renderer/storage) + endpoint; tests.

## 5. Files & changes
### Add
- warnings/notice.py; tests/test_notice.py
### Update
- urls

## 6–10.
Reuses EPIC-05 PDF + EPIC-04 storage. Owner-scoped. No external.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] notice PDF (parties, type, reason, date, disclaimer) via EPIC-05 renderer
- [x] stored encrypted; signed URL
- [x] owner-scoped + kill-switch
- [x] Tests: notice generated
- [x] ruff clean (mypy: only pre-existing manager/factory typing noise shared with T-002 source)

## 12. Test plan
### Automated
- test_notice_pdf_generated
## 13. Acceptance criteria
- [x] Notice PDF; reuses EPIC-05; tests + lint pass.
## 14. Self-review
- [x] Reuses PDF infra; disclaimer present
### Deviations from spec
- Notice generation logic added to existing `warnings/services.py` (`generate_notice`)
  and the endpoint to existing `warnings/views.py` (`WarningNoticeView`) rather than a
  standalone module, mirroring the established thin-view → service pattern; the PDF
  renderer lives in the new `warnings/notice.py` as specified. Endpoint mounted via the
  T-002 `warnings/urls.py` (already under /api/v1/), so no config/urls.py change needed.
- Route is `POST /api/v1/warnings/{id}/notice` (per §2), resolved through
  `Warning.objects.for_user` (owner-scoped, foreign → 404).
### Files touched (actual)
- khatir/warnings/notice.py (new — render_notice_pdf, reuses dmpforms.pdf._render_pdf)
- khatir/warnings/services.py (add generate_notice: render → store_encrypted kind=pdf → persist notice_ref → audit warning.notice → signed_url)
- khatir/warnings/views.py (add WarningNoticeView: kill-switch first, for_user scope, POST)
- khatir/warnings/urls.py (add warnings/<id>/notice route)
- khatir/warnings/tests/test_notice.py (new — 5 tests)
## 15. Notes
- Disclaimer: this is a private notice between landlord and tenant, not a legal judgment.
