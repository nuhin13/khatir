---
id: T-012
epic: EPIC-03
title: Portfolio list screen
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

# T-012 · Portfolio list screen

## 1. Feature goal
Show the landlord's buildings with unit counts and occupancy, with entry points to add a building and open a unit.

## 2. Business logic
Per `portfolio` design. Lists buildings (name, area, units, occupied/vacant), tap → building's units → unit detail. Add-building CTA → wizard.

## 3. What this task DOES
- `features/properties/presentation/screens/portfolio_screen.dart` matching `portfolio`.
- Building cards (summary from /portfolio), expand/drill to units, add-building CTA.
- Loading/error/empty/data. Widget test.

## 5. Files & changes
### Add
- `portfolio_screen.dart`; ARB; `test/portfolio_screen_test.dart`
### Update
- router + landlord shell wiring as needed

## 6. Database changes
None.
## 7. API changes
Consumes /portfolio.

## 8. UI changes
- **Design source:** screen `portfolio` — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('portfolio')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/landlord/home` (portfolio view) or `/properties`
- Translate building cards + counts; values from packages/design-tokens
- States: loading/error/empty (no buildings → add CTA)/data
- Navigation: building → units → `/properties/unit/:id`; add → `/properties/add`
- i18n keys: `portfolio_title`, `portfolio_units`, `portfolio_occupied`, `portfolio_add_building`, `portfolio_empty` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] portfolio_screen matches design
- [ ] building cards with counts/occupancy
- [ ] drill to units → unit detail
- [ ] add-building CTA → wizard
- [ ] all states incl. empty
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- portfolio_screen_test → renders buildings; empty state; tap navigates
### Manual QA
1. View portfolio; tap a building → units; tap unit → detail.

## 13. Acceptance criteria
- [ ] Portfolio matches design; navigation works; all states.
- [ ] **Screen `portfolio` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; empty state friendly
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- If the design shows portfolio as part of `home` vs a separate tab, follow the design; route accordingly.
