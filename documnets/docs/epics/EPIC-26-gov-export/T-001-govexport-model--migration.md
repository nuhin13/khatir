---
id: T-001
epic: EPIC-26
title: GovExport model + migration
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [EPIC-05.T-001]
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

# T-001 · GovExport model + migration

## 1. Feature goal
GovExport(landlord FK, period, format_version, file_ref, record_count, status generated/submitted, created_at). Migration + admin + tests.

## 2. Business logic
GovExport(landlord FK, period, format_version, file_ref, record_count, status generated/submitted, created_at). Migration + admin + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
DB as described; backend. Consent + audit on export. Flag: [] (default OFF).

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
GovExport(landlord FK, period, format_version, file_ref, record_count, status generated/submitted, created_at). Migration + admin + tests.
