---
id: T-006
epic: EPIC-09
title: Dashboard screen
layer: mobile
size: M
status: done
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
- [x] dashboard_screen matches design
- [x] 6-month collection KBarChart
- [x] occupancy KDonutChart
- [x] income-vs-expense chart
- [x] top expense categories
- [x] late-payers list (with quick-request)
- [x] Charts tab wired in landlord shell
- [x] all states (loading/empty/data/error)
- [x] ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- dashboard_screen_test → renders charts; empty state
### Manual QA
1. Charts tab → all charts populated with real data.

## 13. Acceptance criteria
- [x] Dashboard matches design; all charts live; Charts tab wired.
- [x] **Screen `dashboard` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens via theme; all 4 states
### Deviations from spec
- The committed T-004 data layer exposes only `latePayerCount` (no per-tenant
  late-payers list), and the `dashboard` proto has no late-payers list either.
  So the "late-payers list" is realised as a late-payers summary card showing
  the overdue count plus, when count > 0, a quick-request CTA routing to
  `/rent/request` — satisfying the checklist within the committed data shape.
- Added an income-vs-expense trend block (KLineChart over the monthly series'
  collected amounts) + a sage/rose legend, since the §8 spec names it though the
  proto only shows income/collection/occupancy/expenses.
- Occupancy ring uses the server `occupancy_rate` (0..1) so the percentage
  matches backend rounding (e.g. 11/14 → 78%, not the 79% a client recompute
  would give); the count ratio is the fallback when the rate is absent.
- Collection bars are rendered as each month's collected amount as a % of the
  window's peak month (relative heights, max 100%), matching the proto's
  relative-height bars without a per-month rate the payload doesn't carry.
### Files touched (actual)
- Add: lib/features/dashboard/presentation/screens/dashboard_screen.dart;
  test/dashboard_screen_test.dart
- Update: lib/core/router/app_router.dart (Charts branch →
  DashboardScreen, removing the EPIC-09 placeholder); lib/l10n/app_bn.arb +
  lib/l10n/app_en.arb (dashboard_* keys)

## 15. Notes for the implementing agent
- EPIC-02 left a placeholder on the Charts tab with `// TODO(EPIC-09)` — remove it here.
