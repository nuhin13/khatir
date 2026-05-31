---
id: T-007
epic: EPIC-08
title: Flutter maintenance+expense data layer
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, T-003]
blocks: [T-008, T-009, T-010, T-011]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] freezed models
- [ ] maintenance repo (queue/resolve)
- [ ] expense repo (CRUD/export)
- [ ] providers
- [ ] tests (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_maintenance_repo, test_expense_repo
### Manual QA
1. List + resolve via repo.

## 13. Acceptance criteria
- [ ] Typed data layer; tests + analyze pass.

## 14. Self-review
- [ ] Wire schema matches backend
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Enums per enums.md.
