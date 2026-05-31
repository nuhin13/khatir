---
id: T-008
epic: EPIC-09
title: Collection rate + occupancy summary cards
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-004]
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

# T-008 · Collection rate + occupancy summary cards

## 1. Feature goal
Reusable `KMetricCard` widget for showing a single KPI (collection rate %, occupancy %, amount) — used by dashboard and home.

## 2. Business logic
A simple card: icon, label, value, optional trend arrow. Themed. Used across the dashboard for the top summary row.

## 3. What this task DOES
- KMetricCard widget + widget test.

## 5. Files & changes
### Add
- lib/core/widgets/k_metric_card.dart; test

## 6–10.
No DB/API/external/flags; component only.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] KMetricCard (icon, label, value, trend)
- [ ] token-themed
- [ ] widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- k_metric_card_test → renders value + label
## 13. Acceptance criteria
- [ ] Reusable metric card; tokens; test passes.
## 14. Self-review
- [ ] No inline colors; flexible enough for collection + occupancy + amounts
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Keep it generic (not collection-specific).
