---
id: T-008
epic: EPIC-22
title: Manager team screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
blocks: []
external_services: []
feature_flags: [b2b_manager_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Manager team screen

## 1. Feature goal
Manage team members: list staff/sub-managers, add member, set permissions, remove. Per-member role + scope.

## 2. Business logic
Manage team members: list staff/sub-managers, add member, set permissions, remove. Per-member role + scope. Per `mgrTeam` design.

## 3. What this task DOES
- mgrTeam_screen matching the `mgrTeam` design; manager-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/manager/presentation/screens/mgrTeam_screen.dart; ARB; test
### Update
- router `/manager/team`; manager shell wiring

## 6–10.
No DB; consumes manager endpoints; mobile 🟢 (manager role); flag b2b_manager_enabled.

## 8. UI changes
- **Design source:** screen `mgrTeam` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('mgrTeam')`)
- Surface: mobile · **Lane:** 🟢 mobile (manager role)
- Route: `/manager/team`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: mgr_team_title, mgr_team_add, mgr_team_role, mgr_team_remove (bn + en) — lift copy from `mgrTeam`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] mgrTeam_screen matches design
- [ ] manager-scoped data (active-linked owners)
- [ ] all states
- [ ] route `/manager/team` + manager shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- mgrTeam_test → renders; manager-scoped
### Manual QA
1. Log in as manager → this screen → correct cross-owner data.

## 13. Acceptance criteria
- [ ] Screen matches `mgrTeam` design; manager-scoped; all states.
- [ ] **Screen `mgrTeam` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; active-linked owners only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Manage team members: list staff/sub-managers, add member, set permissions, remove. Per-member role + scope.
