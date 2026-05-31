---
id: T-010
epic: EPIC-18
title: Compliance disclaimer + tier gate test
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-004]
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

# T-010 · Compliance disclaimer + tier gate test

## 1. Feature goal
Tests: disclaimer text present in generated doc + PDF; free-tier blocked with upgrade error; required clauses always present even when AI omits them.

## 2. Business logic
Tests: disclaimer text present in generated doc + PDF; free-tier blocked with upgrade error; required clauses always present even when AI omits them.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Cross-cutting test. No external (beyond gateway/PDF). No new flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Tests
- [ ] ruff + mypy clean

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
Tests: disclaimer text present in generated doc + PDF; free-tier blocked with upgrade error; required clauses always present even when AI omits them.
