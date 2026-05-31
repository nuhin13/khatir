---
id: T-006
epic: EPIC-09
title: Dashboard screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004, T-005]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Dashboard screen

## 1. Feature goal
The full `dashboard` screen: collection bar chart, occupancy donut, income-vs-expense, top expense categories, late payers — the Charts tab in the landlord shell.

## 2. Business logic
Per `dashboard` design. Fetches /dashboard; maps to charts; late-payers → quick-request. Fills the Charts tab placeholder from EPIC-02.

## 3. What this task DOES
- dashboard_screen.dart matching `dashboard`; compose chart widgets + summary cards; wire Charts tab; all states. Widget test.

## 5. Files & changes
### Add
- features/dashboard/presentation/screens/dashboard_screen.dart; ARB; test
### Update
- landlord shell Charts branch → dashboard_screen

## 6–10.
No DB; consumes /dashboard; surface mobile 🟢; no external; no flags.

## 8. UI changes
- **Design source:** screen `dashboard` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('dashboard')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/landlord/dashboard`
- Translate chart layout + summary cards + late-payers list; values from packages/design-tokens
- States: loading / error / empty (new landlord, no data) / data
- Navigation: late-payer quick-request → /rent/request
- i18n keys: `dashboard_collection`, `dashboard_occupancy`, `dashboard_income`, `dashboard_expenses`, `dashboard_late`, `dashboard_empty` (bn + en) — lift copy from `dashboard`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] dashboard_screen matches design
- [ ] 6-month collection KBarChart
- [ ] occupancy KDonutChart
- [ ] income-vs-expense chart
- [ ] top expense categories
- [ ] late-payers list (with quick-request)
- [ ] Charts tab wired in landlord shell
- [ ] all states (loading/empty/data/error)
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- dashboard_screen_test → renders charts; empty state
### Manual QA
1. Charts tab → all charts populated with real data.

## 13. Acceptance criteria
- [ ] Dashboard matches design; all charts live; Charts tab wired.
- [ ] **Screen `dashboard` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens via theme; all 4 states
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- EPIC-02 left a placeholder on the Charts tab with `// TODO(EPIC-09)` — remove it here.
