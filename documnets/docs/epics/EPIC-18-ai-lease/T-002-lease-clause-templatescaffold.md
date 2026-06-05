---
id: T-002
epic: EPIC-18
title: Lease clause template/scaffold
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
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

# T-002 · Lease clause template/scaffold

## 1. Feature goal
A compliant base lease structure (DNCC/DSCC-aware sections: parties, premises, rent, advance, term, obligations, termination, dispute) with placeholders the AI fills. Bangla + English. The scaffold guarantees required clauses exist even if AI output varies.

## 2. Business logic
A compliant base lease structure (DNCC/DSCC-aware sections: parties, premises, rent, advance, term, obligations, termination, dispute) with placeholders the AI fills. Bangla + English. The scaffold guarantees required clauses exist even if AI output varies.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. No external (beyond gateway).  

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `khatir/leasedocs/scaffold.py` (bilingual DNCC/DSCC clause scaffold)
- [x] validation / required-clause guarantee — `ensure_required_clauses()` back-fills + `LeaseDocumentClauseKey` enum drives `REQUIRED_CLAUSE_KEYS`
- [x] Tests — `tests/test_scaffold.py` (19 tests); leasedocs suite 40/40 pass
- [x] ruff clean — `ruff check khatir/leasedocs` passes; `makemigrations --check` no changes

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] Required clauses guaranteed; disclaimer present; conventions
### Deviations from spec
- The base structure is modelled as a bilingual clause-spec scaffold in a new `scaffold.py` (clause keys as a `LeaseDocumentClauseKey` TextChoices enum), keeping the model thin. `REQUIRED_CLAUSE_KEYS` now references the enum so the mandatory subset stays in lock-step with the scaffold. `missing_required_clauses()` was extended to treat a scaffold-shaped dict clause with an empty `body` as missing (string-bodied T-001 clauses still validate unchanged).
### Files touched (actual)
- `apps/api/khatir/leasedocs/scaffold.py` (new) — `CLAUSE_SCAFFOLD`, `build_scaffold_content()`, `ensure_required_clauses()`, bilingual disclaimer constants.
- `apps/api/khatir/leasedocs/enums.py` — added `LeaseDocumentClauseKey`.
- `apps/api/khatir/leasedocs/models.py` — `REQUIRED_CLAUSE_KEYS` from enum; dict-body emptiness in `missing_required_clauses()`.
- `apps/api/khatir/leasedocs/tests/test_scaffold.py` (new) — 19 scaffold/guarantee tests.
## 15. Notes
A compliant base lease structure (DNCC/DSCC-aware sections: parties, premises, rent, advance, term, obligations, termination, dispute) with placeholders the AI fills. Bangla + English. The scaffold guarantees required clauses exist even if AI output varies.
