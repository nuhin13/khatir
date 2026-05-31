---
id: T-010
epic: EPIC-17
title: Verification result privacy test (no raw data)
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

# T-010 · Verification result privacy test (no raw data)

## 1. Feature goal
A test asserting that across the full verify flow, no raw EC field is ever persisted, returned, or logged — only matched/not_matched/error + opaque provider_ref. This is a privacy gate.

## 2. Business logic
A test asserting that across the full verify flow, no raw EC field is ever persisted, returned, or logged — only matched/not_matched/error + opaque provider_ref. This is a privacy gate.

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
A test asserting that across the full verify flow, no raw EC field is ever persisted, returned, or logged — only matched/not_matched/error + opaque provider_ref. This is a privacy gate.
