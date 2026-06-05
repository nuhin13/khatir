---
id: T-007
epic: EPIC-08
title: Flutter maintenance+expense data layer
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, T-003]
blocks: [T-008, T-009, T-010, T-011]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Flutter maintenance+expense data layer

## 1. Feature goal
Typed data layer for maintenance + expenses (models, repos, providers).

## 2. Business logic
freezed MaintenanceRequest/Expense; repos: maintenance queue/resolve, expense CRUD/export; providers.

## 3. What this task DOES
- Models + repos + providers + tests (mocked).

## 5. Files & changes
### Add
- features/maintenance/data/{models,maintenance_repository,expense_repository,providers}.dart; test

## 6. Database changes
None.
## 7. API changes
Consumes maintenance + expense endpoints.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] freezed models
- [x] maintenance repo (queue/resolve)
- [x] expense repo (CRUD/export)
- [x] providers
- [x] tests (mocked)
- [x] analyze + test pass

## 12. Test plan
### Automated
- test_maintenance_repo, test_expense_repo
### Manual QA
1. List + resolve via repo.

## 13. Acceptance criteria
- [x] Typed data layer; tests + analyze pass.

## 14. Self-review
- [x] Wire schema matches backend
### Deviations from spec
- None. Models/repos mirror the committed T-002/T-003 serializers exactly.
- The summary aggregation types (ExpenseSummary/by_category/by_month) and the
  CSV export helper were added here so T-012 (expense summary hook) consumes a
  ready typed slice; both come straight off the existing backend endpoints.
### Files touched (actual)
- apps/mobile/lib/features/maintenance/data/models/maintenance_enums.dart (add)
- apps/mobile/lib/features/maintenance/data/models/models.dart (+ models.freezed.dart) (add)
- apps/mobile/lib/features/maintenance/data/maintenance_repository.dart (add)
- apps/mobile/lib/features/maintenance/data/expense_repository.dart (add)
- apps/mobile/lib/features/maintenance/data/providers.dart (add)
- apps/mobile/lib/core/network/api_endpoints.dart (update: maintenance/expenses paths)
- apps/mobile/test/maintenance_data_layer_test.dart (add)

## 15. Notes for the implementing agent
- Enums per enums.md.
