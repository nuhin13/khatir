---
id: T-008
epic: EPIC-08
title: Flutter expenses list screen
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

# T-008 · Flutter expenses list screen

## 1. Feature goal
Show expenses (filterable by building/unit/date) with totals and an add-expense entry + export.

## 2. Business logic
Per `expenses` design. List + filters + totals; add CTA → addExpense; export → CSV share (T-011).

## 3. What this task DOES
- expenses_screen matching `expenses`; filters; totals; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/screens/expenses_screen.dart; ARB; test
### Update
- router /expenses

## 6. Database changes
None.
## 7. API changes
Consumes /expenses.

## 8. UI changes
- **Design source:** screen `expenses` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('expenses')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/expenses`
- Translate list + filters + totals; values from packages/design-tokens
- States: loading/error/empty/data
- Navigation: add → /expenses/add; export → CSV share
- i18n keys: `expenses_title`, `expenses_total`, `expenses_add`, `expenses_export`, `expenses_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] expenses_screen matches design
- [x] filters + totals
- [x] add CTA + export entry
- [x] states; route; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- expenses_screen_test → list, filter, empty
### Manual QA
1. View expenses; filter by building; see totals.

## 13. Acceptance criteria
- [x] Expenses list matches design; filters/totals; states.
- [x] **Screen `expenses` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens
### Deviations from spec
- Filters: implemented as a building filter row (driven by `buildingsProvider`)
  mapping to `ExpenseFilter.buildingId`. The `expenses` prototype shows no
  explicit filter chips; the data layer's `ExpenseFilter` supports
  building/unit/date, so the building axis was surfaced (graceful "All"-only
  while buildings load / on read failure). Unit/date narrowing remain available
  on the typed filter for the export and future hooks.
- The prototype's "New requests" section (maintenance queue) belongs to the
  maintenance-queue screen (T-010); this expenses screen focuses on the totals
  hero + the manual + maintenance-sourced expense list per §3.
- Export reuses a new `ExpenseCsvSharer` (share_plus) seam mirroring the EPIC-07
  receipt sharer, so the CSV from `ExpenseRepository.exportCsv` is shared as an
  `expenses.csv` attachment; failures degrade to a friendly snackbar.

### Files touched (actual)
- apps/mobile/lib/features/maintenance/presentation/screens/expenses_screen.dart (add)
- apps/mobile/lib/features/maintenance/data/expense_csv_sharer.dart (add)
- apps/mobile/lib/core/router/app_router.dart (update: /expenses route)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (add expenses_* keys)
- apps/mobile/test/expenses_screen_test.dart (add)

## 15. Notes for the implementing agent
- Includes both manual + maintenance-sourced expenses; show source chip.
