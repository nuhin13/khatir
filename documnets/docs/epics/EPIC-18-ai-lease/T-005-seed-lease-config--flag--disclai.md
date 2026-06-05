---
id: T-005
epic: EPIC-18
title: Seed lease config + flag + disclaimer
layer: backend
size: XS
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005, EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [ai_lease_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Seed lease config + flag + disclaimer

## 1. Feature goal
Seed ai_lease_enabled flag (on), lease_template_version, lease_disclaimer_text (bn/en: 'This is an AI-generated draft, not legal advice. Consult a lawyer.').

## 2. Business logic
Seed ai_lease_enabled flag (on), lease_template_version, lease_disclaimer_text (bn/en: 'This is an AI-generated draft, not legal advice. Consult a lawyer.').

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. No external (beyond gateway).  Seeds flag + config.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] validation / required-clause guarantee
- [ ] Tests 
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tests + lint pass.
## 14. Self-review
- [ ] Required clauses guaranteed; disclaimer present; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
Seed ai_lease_enabled flag (on), lease_template_version, lease_disclaimer_text (bn/en: 'This is an AI-generated draft, not legal advice. Consult a lawyer.').
