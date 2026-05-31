---
id: T-003
epic: EPIC-20
title: Warning notice PDF (reuse EPIC-05)
layer: backend
size: S
status: todo
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
- [ ] notice PDF (parties, type, reason, date, disclaimer) via EPIC-05 renderer
- [ ] stored encrypted; signed URL
- [ ] owner-scoped + kill-switch
- [ ] Tests: notice generated
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_notice_pdf_generated
## 13. Acceptance criteria
- [ ] Notice PDF; reuses EPIC-05; tests + lint pass.
## 14. Self-review
- [ ] Reuses PDF infra; disclaimer present
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Disclaimer: this is a private notice between landlord and tenant, not a legal judgment.
