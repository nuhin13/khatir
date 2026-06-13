---
id: T-005
epic: EPIC-09
title: fl_chart shared chart widgets
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-008]
blocks: [T-006, T-009]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · fl_chart shared chart widgets

## 1. Feature goal
Reusable `KBarChart`, `KDonutChart`, `KLineChart` widgets (fl_chart) themed to Notun Din tokens — used by dashboard and any future chart.

## 2. Business logic
Per dashboard design. Bar (monthly series), donut (occupancy/category), line (trend). Themed: sage primary, rose accent, token colors. Empty + loading states. Bangla number formatting.

## 3. What this task DOES
- Three chart widgets in `lib/core/widgets/charts/`; tokens; empty/loading; widget tests.

## 5. Files & changes
### Add
- lib/core/widgets/charts/{k_bar_chart,k_donut_chart,k_line_chart}.dart; test
### Update
- pubspec (fl_chart if not already)

## 6–10.
No DB/API; no new UI screens (widgets); no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] KBarChart (monthly, labeled axes, token colors) — `a944982`
- [x] KDonutChart (percentage, center label) — `a944982`
- [x] KLineChart (trend) — `a944982`
- [x] all themed from tokens (no inline hex) — `a944982`
- [x] Bangla numeral formatting — `a944982`
- [x] empty + loading states — `a944982`
- [x] widget tests — `a944982`
- [x] analyze + test pass — `a944982`

## 12. Test plan
### Automated
- chart widget tests render correctly with data + empty
### Manual QA
1. Charts look correct on a device with real data.

## 13. Acceptance criteria
- [x] Three themed, reusable chart widgets; tokens; empty/loading; tests pass.

## 14. Self-review
- [x] No inline colors; tokens; Bangla numerals
### Deviations from spec
- Added `lib/core/widgets/charts/chart_states.dart` (shared `ChartLoadingState` /
  `ChartEmptyState`) so the three charts reuse one loading-spinner + empty-state
  widget instead of duplicating it three times. Still token-only.
- `KDonutChart` exposes a `.percentage()` convenience factory for the common
  single-arc occupancy/collection ring (sage arc on a sage-bg track) with a
  locale-formatted `NN%` center label; the generic multi-slice constructor
  remains for category/occupancy breakdowns.
- Charts stay generic per §15: callers (T-006) supply already-localized axis /
  center labels; numerals on the bar value labels + the donut `.percentage`
  factory are formatted via `BanglaNumerals` from the passed `localeCode`.
- fl_chart pinned to ^1.2.0 (latest stable on pub.dev; no beta/RC).
### Files touched (actual)
- Add: lib/core/widgets/charts/k_bar_chart.dart, k_donut_chart.dart,
  k_line_chart.dart, chart_states.dart
- Add: test/chart_widgets_test.dart
- Update: pubspec.yaml (fl_chart ^1.2.0), pubspec.lock

## 15. Notes for the implementing agent
- Keep charts thin wrappers over fl_chart. The business data → chart data mapping lives in the screen (T-006), not the widgets. Charts are generic.
