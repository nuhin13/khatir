---
id: T-008
epic: EPIC-25
title: Caretaker log screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: [gatekeeper_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Caretaker log screen

## 1. Feature goal
Browseable visitor/event log for assigned buildings: date-filterable history of entries + their status.

## 2. Business logic
Browseable visitor/event log for assigned buildings: date-filterable history of entries + their status. Per `careLog` design.

## 3. What this task DOES
- careLog_screen matching the `careLog` design; caretaker-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/gatekeeper/presentation/screens/careLog_screen.dart; ARB; test
### Update
- router `/caretaker/log`; caretaker shell wiring

## 6–10.
No DB; consumes caretaker endpoints; mobile 🟢 (caretaker role); flag gatekeeper_enabled.

## 8. UI changes
- **Design source:** screen `careLog` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('careLog')`)
- Surface: mobile · **Lane:** 🟢 mobile (caretaker role)
- Route: `/caretaker/log`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: care_log_title, care_log_date, care_log_status, care_log_empty (bn + en) — lift copy from `careLog`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] careLog_screen matches design
- [ ] caretaker-scoped data (assigned buildings)
- [ ] all states
- [ ] route `/caretaker/log` + caretaker shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- careLog_test → renders; caretaker-scoped
### Manual QA
1. Log in as caretaker → this screen → correct assigned-building data.

## 13. Acceptance criteria
- [ ] Screen matches `careLog` design; caretaker-scoped; all states.
- [ ] **Screen `careLog` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; assigned-buildings only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Browseable visitor/event log for assigned buildings: date-filterable history of entries + their status.
