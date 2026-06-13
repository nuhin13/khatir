---
id: T-003
epic: EPIC-18
title: AI lease generation service (via gateway)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-14.T-007]
blocks: []
external_services: [ai_chat]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · AI lease generation service (via gateway)

## 1. Feature goal
generate_lease_document(lease): build prompt from lease data + scaffold → call AI gateway (lease category) → parse into clause content_json → store as draft. Validates required clauses present (falls back to scaffold text if AI omits). Tests (mocked gateway).

## 2. Business logic
generate_lease_document(lease): build prompt from lease data + scaffold → call AI gateway (lease category) → parse into clause content_json → store as draft. Validates required clauses present (falls back to scaffold text if AI omits). Tests (mocked gateway).

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. External: AI gateway (lease category).  

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `khatir/leasedocs/services.py` (`generate_lease_document`, `build_lease_prompt`)
- [x] validation / required-clause guarantee — `ensure_required_clauses()` back-fills omitted clauses from scaffold; `full_clean()` enforces required set
- [x] Tests (mocked gateway) — `tests/test_services.py` (8 tests, `call_gateway` mocked); leasedocs suite green
- [x] ruff clean — `ruff check .` passes; `makemigrations --check` no changes (no model changes)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] Required clauses guaranteed; disclaimer present; conventions
### Deviations from spec
- Generation service lives in a new `khatir/leasedocs/services.py` (model-thin, T-001/T-002 untouched). The prompt is sent as a **structured** gateway payload (`{category, facts, scaffold}`) rather than an opaque prose string, so the gateway/tests can reason about exactly what was sent and the model knows which clause keys to return. Parsing tolerates both scaffold-shaped dict clauses and bare body strings, and a clause map returned either under `data.clauses` or directly under `data`. No DB/model change → no migration.
### Files touched (actual)
- `apps/api/khatir/leasedocs/services.py` (new) — `build_lease_prompt()`, `generate_lease_document()`, clause parsing + scaffold fallback.
- `apps/api/khatir/leasedocs/tests/test_services.py` (new) — 8 mocked-gateway tests (prompt build, parsing, required-clause back-fill, audit, error propagation/rollback).
## 15. Notes
generate_lease_document(lease): build prompt from lease data + scaffold → call AI gateway (lease category) → parse into clause content_json → store as draft. Validates required clauses present (falls back to scaffold text if AI omits). Tests (mocked gateway).
