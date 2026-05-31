---
id: T-005
epic: EPIC-09
title: fl_chart shared chart widgets
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-008]
blocks: [T-006, T-009]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] KBarChart (monthly, labeled axes, token colors)
- [ ] KDonutChart (percentage, center label)
- [ ] KLineChart (trend)
- [ ] all themed from tokens (no inline hex)
- [ ] Bangla numeral formatting
- [ ] empty + loading states
- [ ] widget tests
- [ ] analyze + test pass

## 12. Test plan
### Automated
- chart widget tests render correctly with data + empty
### Manual QA
1. Charts look correct on a device with real data.

## 13. Acceptance criteria
- [ ] Three themed, reusable chart widgets; tokens; empty/loading; tests pass.

## 14. Self-review
- [ ] No inline colors; tokens; Bangla numerals
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep charts thin wrappers over fl_chart. The business data → chart data mapping lives in the screen (T-006), not the widgets. Charts are generic.
