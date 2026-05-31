---
id: T-003
epic: EPIC-18
title: AI lease generation service (via gateway)
layer: backend
size: M
status: todo
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
- [ ] Core implementation per goal
- [ ] validation / required-clause guarantee
- [ ] Tests (mocked gateway)
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
generate_lease_document(lease): build prompt from lease data + scaffold → call AI gateway (lease category) → parse into clause content_json → store as draft. Validates required clauses present (falls back to scaffold text if AI omits). Tests (mocked gateway).
