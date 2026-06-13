---
id: T-009
epic: EPIC-22
title: Manager report screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-005]
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

# T-009 · Manager report screen

## 1. Feature goal
Per-owner report: select owner → generate report → PDF preview/share (reuse EPIC-05 share). Shows collection/occupancy/expense summary.

## 2. Business logic
Per-owner report: select owner → generate report → PDF preview/share (reuse EPIC-05 share). Shows collection/occupancy/expense summary. Per `mgrReport` design.

## 3. What this task DOES
- mgrReport_screen matching the `mgrReport` design; manager-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/manager/presentation/screens/mgrReport_screen.dart; ARB; test
### Update
- router `/manager/report`; manager shell wiring

## 6–10.
No DB; consumes manager endpoints; mobile 🟢 (manager role); flag b2b_manager_enabled.

## 8. UI changes
- **Design source:** screen `mgrReport` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('mgrReport')`)
- Surface: mobile · **Lane:** 🟢 mobile (manager role)
- Route: `/manager/report`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: mgr_report_owner, mgr_report_generate, mgr_report_share (bn + en) — lift copy from `mgrReport`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] mgrReport_screen matches design
- [ ] manager-scoped data (active-linked owners)
- [ ] all states
- [ ] route `/manager/report` + manager shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- mgrReport_test → renders; manager-scoped
### Manual QA
1. Log in as manager → this screen → correct cross-owner data.

## 13. Acceptance criteria
- [ ] Screen matches `mgrReport` design; manager-scoped; all states.
- [ ] **Screen `mgrReport` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; active-linked owners only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Per-owner report: select owner → generate report → PDF preview/share (reuse EPIC-05 share). Shows collection/occupancy/expense summary.
