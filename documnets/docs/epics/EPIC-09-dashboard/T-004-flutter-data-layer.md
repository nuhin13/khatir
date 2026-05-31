---
id: T-004
epic: EPIC-09
title: Flutter dashboard data layer
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-002]
blocks: [T-006, T-008, T-009]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Flutter dashboard data layer

## 1. Feature goal
Typed dashboard model + repo + provider.

## 2. Business logic
freezed DashboardData; repo fetchDashboard(months); provider with AsyncValue.

## 3. What this task DOES
- Model + repo + provider + tests (mocked).

## 5. Files & changes
### Add
- features/dashboard/data/{dashboard_model,dashboard_repository,dashboard_providers}.dart; test

## 6–10.
No DB/API changes; consumes /dashboard; no UI; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] DashboardData freezed model
- [ ] repo fetchDashboard
- [ ] provider
- [ ] tests (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_dashboard_repo
## 13. Acceptance criteria
- [ ] Typed dashboard data layer; tests + analyze pass.
## 14. Self-review
- [ ] Wire schema matches backend
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Monthly series as list of {month, collected, expense}.
