---
id: T-006
epic: EPIC-22
title: Manager home screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-02.T-004, T-004]
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

# T-006 · Manager home screen

## 1. Feature goal
Consolidated manager home across linked owners: total portfolio, per-owner cards, links to add-owner + team. Fills EPIC-02 manager shell Home placeholder.

## 2. Business logic
Consolidated manager home across linked owners: total portfolio, per-owner cards, links to add-owner + team. Fills EPIC-02 manager shell Home placeholder. Per `mgrHome` design.

## 3. What this task DOES
- mgrHome_screen matching the `mgrHome` design; manager-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/manager/presentation/screens/mgrHome_screen.dart; ARB; test
### Update
- router `/manager/home`; manager shell wiring

## 6–10.
No DB; consumes manager endpoints; mobile 🟢 (manager role); flag b2b_manager_enabled.

## 8. UI changes
- **Design source:** screen `mgrHome` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('mgrHome')`)
- Surface: mobile · **Lane:** 🟢 mobile (manager role)
- Route: `/manager/home`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: mgr_home_total, mgr_home_owners, mgr_home_add_owner, mgr_home_team (bn + en) — lift copy from `mgrHome`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] mgrHome_screen matches design
- [ ] manager-scoped data (active-linked owners)
- [ ] all states
- [ ] route `/manager/home` + manager shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- mgrHome_test → renders; manager-scoped
### Manual QA
1. Log in as manager → this screen → correct cross-owner data.

## 13. Acceptance criteria
- [ ] Screen matches `mgrHome` design; manager-scoped; all states.
- [ ] **Screen `mgrHome` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; active-linked owners only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Consolidated manager home across linked owners: total portfolio, per-owner cards, links to add-owner + team. Fills EPIC-02 manager shell Home placeholder.
