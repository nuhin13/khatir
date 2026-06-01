---
id: T-008
epic: EPIC-08
title: Flutter expenses list screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-007]
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

# T-008 · Flutter expenses list screen

## 1. Feature goal
List expenses (per building/unit, filterable) with totals and a CSV export action; entry to add expense and view maintenance.

## 2. Business logic
Per `expenses` design. Filter by building/unit/date; show totals; export CSV; add-expense CTA.

## 3. What this task DOES
- expenses_screen matching `expenses`; filters; totals; export; states. Widget test.

## 5. Files & changes
### Add
- features/maintenance/presentation/screens/expenses_screen.dart; ARB; test
### Update
- router /expenses; landlord shell wiring

## 6. Database changes
None.
## 7. API changes
Consumes expenses list + export.

## 8. UI changes
- **Design source:** screen `expenses` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('expenses')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/expenses`
- Translate list + filters + totals; values from packages/design-tokens
- States: loading/error/empty/data
- Navigation: add → /expenses/add; export → CSV
- i18n keys: `expenses_title`, `expenses_total`, `expenses_export`, `expenses_add`, `expenses_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] expenses_screen matches design
- [ ] filters + totals
- [ ] CSV export action
- [ ] add CTA
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- expenses_screen_test → list + totals; export; empty
### Manual QA
1. View expenses; filter; export.

## 13. Acceptance criteria
- [ ] Expenses screen matches design; filters/totals/export work.
- [ ] **Screen `expenses` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Show both manual + auto (from maintenance) expenses.
