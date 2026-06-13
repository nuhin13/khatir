---
id: T-005
epic: EPIC-13
title: Flags console page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-11.T-008]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Flags console page (Next.js)

## 1. Feature goal
A simple table of all feature flags with a toggle switch per row — the feature-management panel.

## 2. Business logic
Lists flags (key, description, scope, status); toggle switch → confirm + toggle. Super+ops. Distinct from the kill-switch panel (T-006).

## 3. What this task DOES
- /features page; flag table with toggles; confirm dialog; TanStack Query. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/features/page.tsx; test
### Update
- sidebar "Features" → /features

## 6–10.
No DB; consumes flags endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Feature Flags + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/features`
- Flag table with toggle switches + confirm dialog

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] flag table (key, desc, scope, toggle) — `flags_console.tsx`
- [x] confirm dialog before toggle — `ToggleConfirm` (role=dialog, aria-modal)
- [x] super+ops route guard — server page `getAuthenticatedAdmin` → {super,ops}
- [x] TanStack Query; refetch after toggle — `invalidateQueries(featureFlagsQueryKey)`
- [x] test: render, toggle fires — `test/flags.test.tsx`
- [x] tsc pass

## 12. Test plan
### Automated
- flags_page renders; toggle fires confirm
## 13. Acceptance criteria
- [x] Flags console; toggles work; tests pass.
## 14. Self-review
- [x] Confirm before toggle; super+ops
### Deviations from spec
- Route/nav guard is **super+ops** (the `platform` section, matching the backend
  `IsPlatformAdmin` gate in `featureflags/views.py`, T-002), not the
  `compliance` role the scaffold's `_nav.ts` previously assigned to Features.
  The Features nav item is de-flagged `comingSoon` and re-gated to `ops` (super
  always sees all). The kill-switch panel stays compliance-owned (T-006).
- The list fetch tolerates both a bare array and a `{ results }` paginated
  envelope (mirrors `test_flag_endpoints.py::test_list_flags`), so it is
  resilient to the global DRF pagination setting.
- Toggle uses a confirm dialog (not the impact-preview modal) since flags carry
  no revenue impact; danger variant when disabling, primary when enabling.
### Files touched (actual)
- Add: apps/admin/src/lib/api/flags.ts (zod-validated fetchFeatureFlags +
  toggleFeatureFlag), apps/admin/src/components/admin/flags_console.tsx
  (FlagsConsole + FlagTable + ToggleConfirm), apps/admin/src/test/flags.test.tsx
- Update: apps/admin/src/app/(dashboard)/features/page.tsx (server page +
  super/ops role guard, replaces ComingSoon stub), apps/admin/src/app/(dashboard)/_nav.ts
  (Features de-flagged comingSoon, re-gated ops), apps/admin/src/test/sidebar.test.tsx
  (Features added to live-pages set)
## 15. Notes
- Kill-switch panel is a separate page (T-006) with extra security friction.
