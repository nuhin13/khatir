---
id: T-004
epic: EPIC-26
title: Export endpoints (generate + download)
layer: backend
size: M
status: todo
preferred_agent: codex
depends_on: [T-002, EPIC-16.T-004]
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

# T-004 · Export endpoints (generate + download)

## 1. Feature goal
POST /api/v1/gov-export (generate package for period), GET /{id} (signed download). Consent respected (per-tenant from EPIC-04/05), audited, owner-scoped, kill-switch/flag gated.

## 2. Business logic
POST /api/v1/gov-export (generate package for period), GET /{id} (signed download). Consent respected (per-tenant from EPIC-04/05), audited, owner-scoped, kill-switch/flag gated.

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
POST /api/v1/gov-export (generate package for period), GET /{id} (signed download). Consent respected (per-tenant from EPIC-04/05), audited, owner-scoped, kill-switch/flag gated.
