---
id: T-006
epic: EPIC-16
title: Enhanced audit log page (Next.js)
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

# T-006 · Enhanced audit log page (Next.js)

## 1. Feature goal
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.

## 2. Business logic
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.

## 3. What this task DOES
See feature goal. Next.js admin UI.

## 5. Files & changes
### Add/Update
- app/(dashboard)/compliance/... ; test.
### Update
- sidebar "Compliance" → /compliance routes.

## 6–10.
No DB; consumes compliance endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Compliance + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Compliance+super route guard; Tailwind tokens

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core UI per description
- [ ] Compliance+super route guard
- [ ] TanStack Query; states
- [ ] Test
- [ ] tsc pass

## 12. Test plan
### Automated
- render test
## 13. Acceptance criteria
- [ ] UI works; compliance+super gate; tests pass.
## 14. Self-review
- [ ] Tailwind tokens; role gate; states
### Deviations from spec
### Files touched (actual)
## 15. Notes
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.
