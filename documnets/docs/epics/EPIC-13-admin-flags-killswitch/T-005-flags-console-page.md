---
id: T-005
epic: EPIC-13
title: Flags console page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, EPIC-11.T-008]
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
- [ ] flag table (key, desc, scope, toggle)
- [ ] confirm dialog before toggle
- [ ] super+ops route guard
- [ ] TanStack Query; refetch after toggle
- [ ] test: render, toggle fires
- [ ] tsc pass

## 12. Test plan
### Automated
- flags_page renders; toggle fires confirm
## 13. Acceptance criteria
- [ ] Flags console; toggles work; tests pass.
## 14. Self-review
- [ ] Confirm before toggle; super+ops
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Kill-switch panel is a separate page (T-006) with extra security friction.
