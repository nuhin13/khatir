---
id: T-005
epic: EPIC-26
title: Seed gov-export config + flag
layer: backend
size: XS
status: todo
preferred_agent: codex
depends_on: [EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [gov_export_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Seed gov-export config + flag

## 1. Feature goal
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.

## 2. Business logic
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
DB as described; backend. Consent + audit on export. Flag: [gov_export_enabled] (default OFF).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Consent respected + audit (where applicable)
- [ ] Tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [ ] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.
