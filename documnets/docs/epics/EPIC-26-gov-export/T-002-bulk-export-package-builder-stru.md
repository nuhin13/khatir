---
id: T-002
epic: EPIC-26
title: Bulk export package builder (structured + PDFs)
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [T-001, EPIC-05.T-003]
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

# T-002 · Bulk export package builder (structured + PDFs)

## 1. Feature goal
Build a package for a landlord + period: a structured data file (official-compatible format, version-tagged) + the relevant DMP PDFs (reuse EPIC-05), zipped, stored encrypted. Pure builder + tests.

## 2. Business logic
Build a package for a landlord + period: a structured data file (official-compatible format, version-tagged) + the relevant DMP PDFs (reuse EPIC-05), zipped, stored encrypted. Pure builder + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
DB as described; backend. Consent + audit on export. Flag: [gov_export_enabled] (default OFF).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `khatir/govexport/builder.py`
- [x] Consent respected + audit (where applicable) — data-sharing consent filter + `govexport.generate` audit
- [x] Tests — `khatir/govexport/tests/test_builder.py` (16 tests)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [x] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
- Builder is flag-agnostic; the `gov_export_enabled` flag is enforced at the endpoint
  layer (T-004/T-005) so the builder stays unit-testable in isolation.
- Consent model: only tenants whose `linked_user` holds a live `pdpa_data_sharing`
  ConsentRecord (granted, not revoked, not expired) are included; tenants with no
  linked app-user account are skipped (no consent could have been captured).
### Files touched (actual)
- `apps/api/khatir/govexport/builder.py` (new) — pure package builder
- `apps/api/khatir/govexport/tests/test_builder.py` (new) — 16 tests
- `apps/api/khatir/core/storage.py` — add `gov_export` storage kind
## 15. Notes
Build a package for a landlord + period: a structured data file (official-compatible format, version-tagged) + the relevant DMP PDFs (reuse EPIC-05), zipped, stored encrypted. Pure builder + tests.
