---
id: T-009
epic: EPIC-08
title: Flutter add-expense screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007]
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

# T-009 · Flutter add-expense screen

## 1. Feature goal
A form to log a manual expense (unit, category, amount, date, note, optional receipt photo).

## 2. Business logic
Per `addExpense` design. Categories from config; amount; date; optional receipt upload (encrypted storage). Save → expense list.

## 3. What this task DOES
- add_expense_screen matching `addExpense`; validation; receipt upload; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/screens/add_expense_screen.dart; ARB; test
### Update
- router /expenses/add

## 6. Database changes
None.
## 7. API changes
Consumes POST /expenses.

## 8. UI changes
- **Design source:** screen `addExpense` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('addExpense')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/expenses/add`
- Translate form; values from packages/design-tokens
- States: data, validation, saving, error
- Navigation: save → expenses list
- i18n keys: `expense_unit`, `expense_category`, `expense_amount`, `expense_date`, `expense_note`, `expense_save` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] add_expense_screen matches design
- [x] categories from config; validation
- [x] optional receipt upload
- [x] save → list
- [x] states; route; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- add_expense_test → validation; save
### Manual QA
1. Add expense → appears in list.

## 13. Acceptance criteria
- [x] Add-expense matches design; saves.
- [x] **Screen `addExpense` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Categories from config; tokens
### Deviations from spec
- The single prototype "Unit · 2C · করিম মঞ্জিল" field is realised as a building
  selector + a unit selector (the `createExpense` call needs the unit id, and a
  unit is only meaningful within a building). Both are token-styled dropdowns fed
  by `buildingsProvider` / `buildingUnitsProvider`.
- The optional receipt photo is picked via the committed `ImagePickerService`
  (gallery) and its filename is threaded into `createExpense(receiptRef:)` — the
  T-007 data layer exposes only a `receipt_ref` string and there is no committed
  media-upload endpoint yet, so the encrypted-storage upload ref is wired through
  the same field once that endpoint lands.
### Files touched (actual)
- apps/mobile/lib/features/maintenance/presentation/screens/add_expense_screen.dart (add)
- apps/mobile/lib/core/router/app_router.dart (update: /expenses/add route + import)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (add: add_expense_title, expense_*)
- apps/mobile/test/add_expense_screen_test.dart (add)

## 15. Notes for the implementing agent
- Receipt photo optional; reuse upload pattern.
