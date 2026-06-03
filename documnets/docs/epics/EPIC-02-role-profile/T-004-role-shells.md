---
id: T-004
epic: EPIC-02
title: Role shell scaffolding (StatefulShellRoute, 3 shells)
layer: mobile
size: M
status: in-progress
preferred_agent: claude-code
depends_on: [EPIC-01.T-012, T-003]
blocks: [T-005, T-006, T-007, T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Role shell scaffolding (StatefulShellRoute, 3 shells)

## 1. Feature goal
Create the three role-based app shells (landlord, manager, tenant) using go_router's `StatefulShellRoute`, each owning its own bottom-nav and independent navigation stack per tab — the structural frame the role experiences live in.

## 2. Business logic
Per `05_navigation_routing.md`: each role shell is a `StatefulShellRoute.indexedStack` with branches per tab. The landlord shell is built fully (its tabs are filled by MVP epics); manager + tenant shells are scaffolded with placeholder bodies (filled by EPIC-22 / EPIC-19). The bottom-nav widget itself is T-006; this task creates the shell structure + branch routes.

## 3. What this task DOES
- `features/shell/landlord_shell.dart`, `manager_shell.dart`, `tenant_shell.dart`.
- Wire three `StatefulShellRoute` blocks in `app_router.dart` with routes:
  - Landlord: `/landlord/home`, `/landlord/dashboard`, `/landlord/rent`, `/landlord/more` (+ the center Add action, not a branch — opens `/tenants/add`).
  - Manager: `/manager/home`, `/manager/dashboard`, `/manager/rent`, `/manager/more`.
  - Tenant: `/tenant/home`, `/tenant/maintenance`, `/tenant/receipts`, `/tenant/more`.
- Each branch initially renders a placeholder body (`KShellPlaceholder` showing the tab name) — later epics replace bodies.
- Each shell renders the `KBottomNav` (built in T-006) — until T-006 lands, a temporary inline nav is acceptable with a `// TODO(T-006)` marker.
- Widget test: each shell builds and switches tabs.

## 4. What this task does NOT do
- The nav component styling/per-role tabs (T-006).
- The actual tab bodies (later epics).
- Role chooser (T-005) and redirect (T-008).

## 5. Files & changes
### Add
- `lib/features/shell/landlord_shell.dart`, `manager_shell.dart`, `tenant_shell.dart`
- `lib/features/shell/widgets/shell_placeholder.dart`
- `test/role_shell_test.dart`
### Update
- `lib/core/router/app_router.dart` — three StatefulShellRoute trees
### Delete
- none (EPIC-01 `/home` placeholder removed in T-008 of this epic)

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
- **Design source:** shells derived from screens `home` / `mgrHome` / `tenHome` + `bottomnav()` in `proto/ui.js` (in-repo: `docs/design/khatir-ui/proto/ui.js`, `screens-landlord.js`, `screens-other.js`)
- Surface: mobile · **Lane:** 🟢 mobile
- Routes: `/landlord/*`, `/manager/*`, `/tenant/*` (StatefulShellRoute branches)
- Translate shell + nav structure; values from `packages/design-tokens`
- States: each placeholder body shows a simple loading/empty until its epic fills it
- Navigation: tab switches via `goNamed`; center Add → `/tenants/add`

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] landlord_shell with 4 branches + center Add action
- [x] manager_shell with 4 branches (placeholder bodies)
- [x] tenant_shell with 4 branches (placeholder bodies)
- [x] StatefulShellRoute wiring in app_router
- [x] KShellPlaceholder body widget
- [x] uses KBottomNav (T-006 already merged) — no temporary nav needed
- [x] Widget test: shells build + tab switch (role_shell_test.dart)
- [ ] analyze + test pass — BLOCKED: no Flutter/Dart toolchain in this env

## 12. Test plan
### Automated
- role_shell_test → each shell builds; switching index changes branch
### Manual QA
1. Force role=landlord → land in landlord shell; tap tabs → placeholder bodies switch.

## 13. Acceptance criteria
- [x] Three shells exist with correct branch routes.
- [x] Tab switching works (indexed stack, independent stacks) — via goBranch.
- [x] Landlord shell ready for MVP epics to fill; manager/tenant stubbed.
- [ ] Test + analyze pass — BLOCKED: no Flutter/Dart toolchain in this env.

## 14. Self-review
- [x] StatefulShellRoute (not manual nav)
- [x] Placeholders clearly marked for later epics (TODO(EPIC-NN) on each branch)
- [x] Tokens via theme (KhatirColors/Spacing/Radius + KBottomNav; no hardcoded hex/px)
### Deviations from spec
- T-006 (KBottomNav) already landed, so the shells use the real `KBottomNav`
  component directly rather than a temporary inline nav.
- The center "Add" action routes to a `/tenants/add` placeholder (EPIC-04 builds
  the real wizard); marked `// TODO(EPIC-04)`.
- l10n codegen could not be run (no toolchain); the generated
  `app_localizations*.dart` files were hand-edited to add the new nav/placeholder
  keys, mirroring what `flutter gen-l10n` would produce from the `.arb` files.
- analyze + test were written but could not be executed here (no Flutter/Dart
  toolchain) — same blocker as EPIC-02/T-003.
### Files touched (actual)
- lib/features/shell/landlord_shell.dart (add)
- lib/features/shell/manager_shell.dart (add)
- lib/features/shell/tenant_shell.dart (add)
- lib/features/shell/widgets/shell_placeholder.dart (add)
- lib/core/router/app_router.dart (update: 3 StatefulShellRoute trees + /tenants/add)
- lib/l10n/app_en.arb, app_bn.arb (add nav_* + shell_placeholder keys)
- lib/l10n/app_localizations.dart, app_localizations_en.dart, app_localizations_bn.dart (regen by hand)
- test/role_shell_test.dart (add)

## 15. Notes for the implementing agent
- The center "Add" (FAB) in the nav is an action, not a tab branch — it pushes `/tenants/add` (which EPIC-04 builds). For now it can route to a placeholder.
- Landlord nav tabs (from `bottomnav()`): Home, Charts(dashboard), Add(FAB), Rent, More. Manager/Tenant adjust per their `home` target; keep the same 5-slot structure unless the design shows otherwise.
- Leave clear `// TODO(EPIC-NN)` markers on each placeholder body naming the epic that fills it (home→EPIC-03/09, rent→EPIC-07, etc.).
