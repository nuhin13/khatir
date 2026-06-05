---
id: T-004
epic: EPIC-26
title: Export endpoints (generate + download)
layer: backend
size: M
status: done
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
- [x] Core implementation per goal — POST /api/v1/gov-export + GET /{id} (views, urls, serializers)
- [x] Consent respected + audit (where applicable) — builder filters consenting tenants; generate + download audit rows
- [x] Tests — khatir/govexport/tests/test_endpoints.py (19 tests)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [x] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
- None. POST generate + GET signed-download wired under /api/v1/, owner-scoped (foreign id → 404), flag-gated default OFF via `gov_export_enabled`.
### Files touched (actual)
- apps/api/khatir/govexport/views.py (new)
- apps/api/khatir/govexport/urls.py (new)
- apps/api/khatir/govexport/serializers.py (new)
- apps/api/khatir/govexport/flags.py (new)
- apps/api/khatir/govexport/tests/test_endpoints.py (new)
- apps/api/config/urls.py (mount govexport urls)
## 15. Notes
POST /api/v1/gov-export (generate package for period), GET /{id} (signed download). Consent respected (per-tenant from EPIC-04/05), audited, owner-scoped, kill-switch/flag gated.
