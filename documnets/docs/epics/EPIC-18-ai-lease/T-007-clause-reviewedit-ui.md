---
id: T-007
epic: EPIC-18
title: Clause review/edit UI
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-006]
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

# T-007 · Clause review/edit UI

## 1. Feature goal
Editable clause list — each AI-generated clause shown as an editable section; landlord can modify text before finalizing. Required clauses can't be deleted (only edited). Saves via PATCH lease-document.

## 2. Business logic
Editable clause list — each AI-generated clause shown as an editable section; landlord can modify text before finalizing. Required clauses can't be deleted (only edited). Saves via PATCH lease-document.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No DB; consumes lease-document endpoints; mobile 🟢. No external (beyond gateway/PDF). No new flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Tests
- [ ] analyze + test pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tests pass.
## 14. Self-review
- [ ] Disclaimer/required clauses preserved; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
Editable clause list — each AI-generated clause shown as an editable section; landlord can modify text before finalizing. Required clauses can't be deleted (only edited). Saves via PATCH lease-document.
