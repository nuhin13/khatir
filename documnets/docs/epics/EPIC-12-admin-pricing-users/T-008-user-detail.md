---
id: T-008
epic: EPIC-12
title: User detail + actions page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, EPIC-11.T-008]
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

# T-008 · User detail + actions page (Next.js)

## 1. Feature goal
Full user profile with subscription, usage, audit trail, and action buttons (suspend/reactivate/upgrade).

## 2. Business logic
Loads /admin/users/{id}. Shows: profile, tier + usage, subscription history, recent actions, audit trail. Action buttons: suspend (requires reason), reactivate, manual upgrade. All confirm dialogs with reason. Ops+super.

## 3. What this task DOES
- /users/[id] page; action dialogs; audit trail section. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/users/[id]/page.tsx; test

## 6–10.
No DB; consumes user detail + action endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §User Detail + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/users/[id]`
- Profile + subscription + audit trail + action buttons
- States: loading / active / suspended

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] profile + tier + usage sections
- [ ] audit trail (recent admin actions)
- [ ] suspend dialog (reason required)
- [ ] reactivate + upgrade buttons
- [ ] all actions confirm + refetch
- [ ] ops+super gate
- [ ] tests: render, action dialogs fire
- [ ] tsc pass

## 12. Test plan
### Automated
- user_detail renders profile + audit; suspend opens dialog
## 13. Acceptance criteria
- [ ] User detail + all actions; reason required; tests pass.
## 14. Self-review
- [ ] Reason required; audit trail visible; role-gated
### Deviations from spec
### Files touched (actual)
## 15. Notes
- After suspend → user detail shows suspended status badge immediately.
