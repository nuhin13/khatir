---
id: T-005
epic: EPIC-14
title: ASR + chat provider stubs (in gateway)
layer: infra
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-003]
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

# T-005 · ASR + chat provider stubs (in gateway)

## 1. Feature goal
Stub ASR (Bangla voice→fields) and chat provider impls in the gateway. Functional enough to route calls; full impls refined when EPIC-18/23 build those features.

## 2. Business logic
Stub ASR (Bangla voice→fields) and chat provider impls in the gateway. Functional enough to route calls; full impls refined when EPIC-18/23 build those features.

## 3. What this task DOES
See feature goal. Implements the above in the correct layer (infra=gateway, backend=Django).

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No new DB tables (beyond T-001). External: AI vendor APIs (mocked in tests). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation
- [ ] Tests (mocked external)
- [ ] ruff + mypy clean (backend); ruff clean (gateway)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tests + lint pass.
## 14. Self-review
- [ ] API keys from config; not logged
### Deviations from spec
### Files touched (actual)
## 15. Notes
Stub ASR (Bangla voice→fields) and chat provider impls in the gateway. Functional enough to route calls; full impls refined when EPIC-18/23 build those features.
