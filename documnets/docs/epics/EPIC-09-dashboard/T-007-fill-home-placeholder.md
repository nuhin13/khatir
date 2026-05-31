---
id: T-007
epic: EPIC-09
title: Fill home screen chart placeholder (EPIC-03)
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-006, EPIC-03.T-009]
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

# T-007 · Fill home screen chart placeholder (EPIC-03)

## 1. Feature goal
Replace the `// TODO(EPIC-09)` chart placeholder on the landlord home screen with a real summary collection card.

## 2. Business logic
The home screen (`home`) has a collection-summary card region left as a placeholder by EPIC-03 T-009. This task fills it with the current month's collection summary (from /dashboard), linking to the full dashboard.

## 3. What this task DOES
- Collection summary card widget on home; replace placeholder; tap → dashboard. Widget test.

## 5. Files & changes
### Update
- EPIC-03 landlord_home_screen.dart — replace chart placeholder with summary card

## 6–10.
No DB; consumes /dashboard (or /portfolio); surface mobile 🟢; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] collection summary card (current month collected/pending)
- [ ] tap → dashboard tab
- [ ] replaces EPIC-03 TODO(EPIC-09)
- [ ] widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- home_summary_card_test
### Manual QA
1. Home shows collection summary; tap → charts tab.

## 13. Acceptance criteria
- [ ] Home chart placeholder replaced; EPIC-03 TODO removed; test passes.

## 14. Self-review
- [ ] EPIC-03 marker removed; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes
- Keep the home card lightweight (just current-month totals). Full charts are on the dedicated dashboard tab.
