---
id: T-009
epic: EPIC-17
title: Verification logs → EPIC-16 compliance viewer
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001, EPIC-16.T-002]
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

# T-009 · Verification logs → EPIC-16 compliance viewer

## 1. Feature goal
Surface VerificationLog entries in the EPIC-16 compliance views (read-only, result + date + who, no raw data). Add a filter for verification events.

## 2. Business logic
Surface VerificationLog entries in the EPIC-16 compliance views (read-only, result + date + who, no raw data). Add a filter for verification events.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
DB reads as needed; backend. No external (beyond verify). No new flags.

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
- [ ] No raw EC data anywhere; follows conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
Surface VerificationLog entries in the EPIC-16 compliance views (read-only, result + date + who, no raw data). Add a filter for verification events.
