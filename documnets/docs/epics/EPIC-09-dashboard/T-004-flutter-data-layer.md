---
id: T-004
epic: EPIC-09
title: Flutter dashboard data layer
layer: mobile
size: S
status: done
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
- [x] DashboardData freezed model
- [x] repo fetchDashboard
- [x] provider
- [x] tests (mocked)
- [x] analyze + test pass

## 12. Test plan
### Automated
- test_dashboard_repo
## 13. Acceptance criteria
- [x] Typed dashboard data layer; tests + analyze pass.
## 14. Self-review
- [x] Wire schema matches backend
### Deviations from spec
- Monthly series keeps `period` as the raw `YYYY-MM` string (per §15 the chart wants the label, not a re-derived DateTime); top-category `category` reuses the shared `ExpenseCategory` enum (same wire values) rather than a new dashboard-local enum.
- Provider exposed as `AsyncNotifierProvider.family<DashboardController, DashboardData, int?>` (keyed by the months window, null = server default) so the screen gets a `refresh()` for pull-to-retry, matching the rent/maintenance controller pattern.
### Files touched (actual)
- Add: lib/features/dashboard/data/{dashboard_model.dart (+ .freezed.dart), dashboard_repository.dart, dashboard_providers.dart}; test/dashboard_data_layer_test.dart
- Update: lib/core/network/api_endpoints.dart (`ApiEndpoints.dashboard`)
## 15. Notes
- Monthly series as list of {month, collected, expense}.
