---
id: T-011
epic: EPIC-08
title: Maintenance entry on unit detail
layer: mobile
size: S
status: done
preferred_agent: codex
depends_on: [T-007, EPIC-03.T-013]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-011 · Maintenance entry on unit detail

## 1. Feature goal
Show recent maintenance + expenses for a unit on the unit detail screen, with a link to the full queue/list.

## 2. Business logic
Adds a maintenance/expense summary section to unit detail (recent items + counts), linking to queue (T-010) and expenses (T-008).

## 3. What this task DOES
- unit maintenance/expense summary widget; integrate into unit detail; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/widgets/unit_maint_expense_section.dart; test
### Update
- EPIC-03 unit_detail_screen.dart

## 6. Database changes
None.
## 7. API changes
Consumes unit maintenance/expense lists.
## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Section on `/properties/unit/:id`
- States: loading/empty/data
- i18n keys: `unit_maintenance`, `unit_expenses`, `unit_view_all` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] unit maintenance/expense summary section
- [x] links to queue + expenses
- [x] integrate into unit detail
- [x] states; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- unit_maint_section_test
### Manual QA
1. Unit detail shows recent maintenance + expenses.

## 13. Acceptance criteria
- [x] Unit detail shows maintenance/expense summary; tests + analyze pass.

## 14. Self-review
- [x] Tokens; links correct
### Deviations from spec
- The `unit` prototype has no maintenance/expense block, so the section is a new
  composition built from the existing soft-card + chip token vocabulary (matching
  the queue/expenses screens), placed below the tenant region.
- Added two unit-scoped reads to T-007 `providers.dart`
  (`unitMaintenanceProvider` / `unitExpensesProvider`) using the existing
  `listQueue(unitId:)` / `ExpenseFilter(unitId:)` slices — no repo changes.
### Files touched (actual)
- apps/mobile/lib/features/maintenance/presentation/widgets/unit_maint_expense_section.dart (add)
- apps/mobile/lib/features/maintenance/data/providers.dart (update: unit-scoped providers)
- apps/mobile/lib/features/properties/presentation/screens/unit_detail_screen.dart (update: render section)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (update: unit_maintenance/unit_expenses/unit_view_all + count/empty/error keys)
- apps/mobile/test/unit_maint_section_test.dart (add)
- apps/mobile/test/unit_detail_test.dart (update: override maintenance/expense repos)

## 15. Notes for the implementing agent
- Keep it a lightweight summary; full lists live in their own screens.
