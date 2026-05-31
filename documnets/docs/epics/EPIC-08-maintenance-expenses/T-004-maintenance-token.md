---
id: T-004
epic: EPIC-08
title: Maintenance web-link token (reuse pattern)
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [EPIC-07.T-002]
blocks: [T-005]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Maintenance web-link token (reuse pattern)

## 1. Feature goal
Token to let a tenant open a maintenance web form for their unit without an app/login.

## 2. Business logic
Reuse EPIC-07 T-002 signing pattern, scoped to a unit/lease (not a rent request). Expiring, signed.

## 3. What this task DOES
- make/resolve maintenance token (unit-scoped). Tests.

## 5. Files & changes
### Add
- maintenance/tokens.py, tests
## 6. Database changes
None (or store on a per-unit basis).
## 7. API changes
None (used by T-005).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] make/resolve unit-scoped maintenance token (reuse EPIC-07 pattern)
- [ ] expiring + signed
- [ ] Tests: valid/expired/tampered
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_token_valid/expired
### Manual QA
1. Generate + resolve a maintenance token.

## 13. Acceptance criteria
- [ ] Unit-scoped maintenance token; tests + lint pass.

## 14. Self-review
- [ ] Reuses EPIC-07 signing; scoped to unit
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Factor the EPIC-07 signing into a shared helper if cleaner; don't duplicate crypto.
