---
id: T-008
epic: EPIC-14
title: Retrofit EPIC-04 OCR through gateway
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-007, EPIC-04.T-005]
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

# T-008 · Retrofit EPIC-04 OCR through gateway

## 1. Feature goal
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.

## 2. Business logic
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.

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
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.
