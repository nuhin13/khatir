---
id: T-010
epic: EPIC-05
title: Template field-verification + golden test
layer: cross-cutting
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
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

# T-010 · Template field-verification + golden test

## 1. Feature goal
Verify the generated PDF matches the **official** DMP form field-by-field, and lock that fidelity with a golden test — the release gate for the wedge.

## 2. Business logic
Obtain the real official DMP tenant-registration form. Map every official field to the assembler (T-002) + renderer (T-003). Produce a golden reference and a test asserting the rendered PDF places each field correctly. This is a release blocker until passed.

## 3. What this task DOES
- Document the official field list (in repo). Reconcile assembler + renderer to it. Add a golden/field-position test. Capture `dmp_template_version` value.

## 5. Files & changes
### Add
- docs note: official DMP field mapping; golden test fixture
- backend test asserting fidelity
### Update
- assembler/renderer to match verified fields

## 6. Database changes
None.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None (but requires the real form as reference input).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] official DMP form obtained + field list documented
- [ ] assembler fields reconciled to official
- [ ] renderer positions reconciled
- [ ] golden/field test added
- [ ] dmp_template_version recorded
- [ ] test passes

## 12. Test plan
### Automated
- golden PDF / field-position assertions
### Manual QA
1. Print generated PDF, overlay on official form — fields align.

## 13. Acceptance criteria
- [ ] Generated PDF matches official form field-by-field; golden test passes.
- [ ] Wedge is release-ready.

## 14. Self-review
- [ ] Every official field accounted for; version captured
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- **This is a hard gate.** Until the rendered form matches the real DMP form, EPIC-05 is not done — flag blocked if the official template can't be verified. Coordinate with the founder (Nuhin) to obtain the authoritative form.
