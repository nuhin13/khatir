---
id: T-001
epic: EPIC-08
title: Maintenance + Expense models, enums, migration
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-03.T-001]
blocks: [T-002, T-003]
external_services: []
feature_flags: []
started_at: 2026-06-04completed_at: 2026-06-04executed_by: claudereviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Maintenance + Expense models, enums, migration

## 1. Feature goal
Create the `maintenance` app with MaintenanceRequest + Expense models.

## 2. Business logic
Per schema Domain 6. MaintenanceRequest(unit, lease nullable, category, description, photo_ref, status, resolved_at, resolution_cost, resolution_note). Expense(unit, category, amount Decimal, date, source, note, receipt_ref). Index Expense(unit, date).

## 3. What this task DOES
- app + both models + enums (MaintenanceCategory/Status, ExpenseCategory/Source); index; admin; migration; factories+tests.

## 5. Files & changes
### Add
- khatir/maintenance/{__init__,apps,models,enums,admin}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
Creates maintenance_maintenancerequest, maintenance_expense. Reversible.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] MaintenanceRequest model
- [ ] Expense model (amount Decimal, source enum)
- [ ] enums match enums.md
- [ ] index Expense(unit,date)
- [ ] admin + migration reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_models_create, money_decimal
### Manual QA
1. Create in admin.

## 13. Acceptance criteria
- [ ] Models per schema; migration clean; tests + lint pass.

## 14. Self-review
- [ ] Money Decimal; enums; index
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- ExpenseSource = request|manual. resolution_cost feeds the auto-expense (T-002).
