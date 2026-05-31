---
id: T-006
epic: EPIC-14
title: Usage logging (per call)
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

# T-006 · Usage logging (per call)

## 1. Feature goal
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.

## 2. Business logic
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.

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
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.
