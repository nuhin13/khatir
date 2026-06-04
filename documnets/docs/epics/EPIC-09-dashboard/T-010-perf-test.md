---
id: T-010
epic: EPIC-09
title: Dashboard performance test
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Dashboard performance test

## 1. Feature goal
Assert the dashboard selectors stay within an acceptable query count (no N+1 regressions).

## 2. Business logic
Use Django's `assertNumQueries` or the query-count assertion pattern with a realistically-sized fixture (e.g. 5 buildings, 20 units, 50 payments) to verify the dashboard runs in a bounded number of DB queries.

## 3. What this task DOES
- A perf/query-count test that fails CI if N+1 is introduced.

## 5. Files & changes
### Add
- dashboard/tests/test_perf.py

## 6–10.
No DB changes; backend only; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] fixture: 5 buildings, 20 units, 50 payments, 20 expenses
- [x] assertNumQueries within bound
- [x] test passes + added to CI

## 12. Test plan
### Automated
- test_dashboard_query_count
### Manual QA
1. Introduce a deliberate N+1 → test fails.

## 13. Acceptance criteria
- [x] Query count bounded; test catches regressions.
## 14. Self-review
- [x] Bound is tight enough to catch real N+1s
### Deviations from spec
- Used `CaptureQueriesContext` with an upper-bound (`assertLessEqual`) rather
  than exact `assertNumQueries`, per §15 guidance to leave room for legitimate
  joins while still catching per-row loops. Budget = 12 (selectors issue ~8
  aggregate passes; any N+1 over the 50 schedules / 20 units adds tens).
### Files touched (actual)
- khatir/dashboard/tests/test_perf.py (add)
## 15. Notes
- Don't over-tighten the bound — leave room for legitimate joins. Focus on catching loops.
