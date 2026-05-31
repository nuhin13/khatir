---
id: T-011
epic: EPIC-08
title: CSV export/share (mobile)
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-004, T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-011 · CSV export/share (mobile)

## 1. Feature goal
Let the landlord export expenses as CSV and share/save it from the device.

## 2. Business logic
Calls the export endpoint, saves the CSV, opens the system share sheet.

## 3. What this task DOES
- Export action (fetch CSV → share_plus); wired into expenses screen. Test (mocked).

## 5. Files & changes
### Add
- export helper; test
### Update
- expenses_screen export button

## 6. Database changes
None.
## 7. API changes
Consumes /expenses/export.
## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Export action on expenses screen
- States: exporting, done (share), error

## 9. External services
None (OS share).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] fetch CSV → save → share
- [ ] wired into expenses screen
- [ ] test (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- export_test → fetch + share invoked
### Manual QA
1. Export → CSV shared/saved.

## 13. Acceptance criteria
- [ ] CSV export/share works; test + analyze pass.

## 14. Self-review
- [ ] Uses share_plus; handles errors
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse share_plus from EPIC-05/07.
