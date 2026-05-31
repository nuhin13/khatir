---
id: T-006
epic: EPIC-13
title: Kill-switch panel page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
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

# T-006 · Kill-switch panel page (Next.js)

## 1. Feature goal
The emergency kill-switch panel — 5 named switches, each requiring MFA re-entry + reason + optional lawyer reference. Visually distinct and friction-heavy by design.

## 2. Business logic
Per admin spec kill-switch UI. Each switch shows: name, description, current state, last event date/actor. Toggle → MFA dialog (re-enter 6-digit code) + reason textarea + optional lawyer reference → confirm. Red warning banner if any switch is OFF. Super only.

## 3. What this task DOES
- /killswitch page; 5 switch rows; MFA re-confirm dialog; reason + lawyer ref; event log per switch; red warning banner. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/killswitch/page.tsx; components/admin/killswitch_dialog.tsx; test
### Update
- sidebar "Kill-switch" → /killswitch

## 6–10.
No DB; consumes killswitch endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Kill-Switch + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/killswitch`
- 5 switch rows + MFA dialog + warning banner when any is OFF
- States: all-on / any-off (warning)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] 5 named switches with state + last event
- [ ] MFA re-confirm dialog (6-digit TOTP)
- [ ] reason textarea + optional lawyer reference
- [ ] red warning banner if any switch OFF
- [ ] super-only route guard
- [ ] event log section per switch
- [ ] test: renders; MFA dialog opens; confirm fires endpoint
- [ ] tsc pass

## 12. Test plan
### Automated
- killswitch_page renders; toggle opens MFA dialog; confirm calls endpoint
### Manual QA
1. Toggle a switch → MFA dialog → enter code + reason → confirmed → switch OFF → red banner appears.

## 13. Acceptance criteria
- [ ] Kill-switch panel with MFA friction; warning banner; event log; super only; tests pass.
## 14. Self-review
- [ ] MFA required; reason required; intentionally friction-heavy
### Deviations from spec
### Files touched (actual)
## 15. Notes
- This is a safety-critical UI. Make it visually scary when switches are off — red banner, warning text.
