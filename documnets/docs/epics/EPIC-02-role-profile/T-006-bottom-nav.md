---
id: T-006
epic: EPIC-02
title: Bottom nav component + per-role tabs
layer: mobile
size: M
status: todo
preferred_agent: claude-code
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

# T-006 · Bottom nav component + per-role tabs

## 1. Feature goal
Build the shared `KBottomNav` widget matching the design's bottom navigation (Home · Charts · Add center-FAB · Rent · More), with the tab set and home target adapting per role, used by all three shells.

## 2. Business logic
From `bottomnav()` in `proto/ui.js`: 5 slots — Home, Charts(dashboard), Add (center FAB, accent), Rent, More. The Home target swaps by role (`home`/`mgrHome`/`tenHome`). The center Add is an action (push), not a tab. Active tab highlighted in sage; FAB filled accent.

## 3. What this task DOES
- `core/widgets/k_bottom_nav.dart` — the styled nav with 5 slots, active state, center FAB.
- Per-role tab config (landlord/manager/tenant) — labels + routes; tenant differs (Home, Maintenance, +, Receipts, More) per its shell.
- Integrate into the three shells (replace T-004's temporary nav).
- Icons from the design icon set; colors from tokens.
- Widget test: renders 5 slots; active highlight; FAB triggers add action.

## 4. What this task does NOT do
- No new screens; just the nav + integration.

## 5. Files & changes
### Add
- `lib/core/widgets/k_bottom_nav.dart`
- `lib/features/shell/shell_nav_config.dart` (per-role tab definitions)
- `test/bottom_nav_test.dart`
### Update
- `landlord_shell.dart`, `manager_shell.dart`, `tenant_shell.dart` — use KBottomNav (remove T-004 temp nav)
### Delete
- temporary inline nav from T-004

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
- **Design source:** `bottomnav()` in `proto/ui.js` (in-repo: `docs/design/khatir-ui/proto/ui.js`)
- Surface: mobile · **Lane:** 🟢 mobile
- Component: `KBottomNav` used by all shells
- Translate nav structure (5 slots, center FAB, active state); values from `packages/design-tokens`
- States: reflects active tab; FAB pressed state
- Navigation: tab → `goNamed`; FAB → push add action
- i18n keys: `nav_home`, `nav_charts`, `nav_add`, `nav_rent`, `nav_more`, `nav_maintenance`, `nav_receipts` (bn + en)

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] KBottomNav: 5 slots, center FAB, active highlight (sage), tokens
- [ ] shell_nav_config per-role tab sets (landlord/manager/tenant)
- [ ] integrated into all 3 shells (temp nav removed)
- [ ] icons from design set; bn/en labels via ARB
- [ ] Widget test: 5 slots, active state, FAB action
- [ ] analyze + test pass; no inline colors/strings

## 12. Test plan
### Automated
- bottom_nav_test → renders slots; active index highlighted; FAB onTap fires
### Manual QA
1. In each shell, confirm correct tabs + labels; active highlight; FAB opens add.

## 13. Acceptance criteria
- [ ] KBottomNav matches design (5 slots, center FAB).
- [ ] Per-role tab sets correct (tenant differs).
- [ ] Used by all three shells.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Single shared nav widget (no per-shell duplication)
- [ ] Tokens/icons/strings from shared sources
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Landlord/Manager tabs: Home · Charts · ➕ · Rent · More. Tenant tabs: Home · Maintenance · ➕(pay?) · Receipts · More — confirm against `tenHome` design; if tenant has no center-add, render a 4-slot variant. Follow the design.
- The FAB action differs by role (landlord → add tenant; tenant → pay rent). Drive it from `shell_nav_config`.
