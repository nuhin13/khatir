---
id: T-006
epic: EPIC-25
title: Caretaker home screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-02.T-004, T-003]
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

# T-006 · Caretaker home screen

## 1. Feature goal
Caretaker home: today's visitor activity for assigned buildings, quick links to review + log. Fills EPIC-02 caretaker shell Home placeholder.

## 2. Business logic
Caretaker home: today's visitor activity for assigned buildings, quick links to review + log. Fills EPIC-02 caretaker shell Home placeholder. Per `careHome` design.

## 3. What this task DOES
- careHome_screen matching the `careHome` design; caretaker-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/gatekeeper/presentation/screens/careHome_screen.dart; ARB; test
### Update
- router `/caretaker/home`; caretaker shell wiring

## 6–10.
No DB; consumes caretaker endpoints; mobile 🟢 (caretaker role); flag gatekeeper_enabled.

## 8. UI changes
- **Design source:** screen `careHome` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('careHome')`)
- Surface: mobile · **Lane:** 🟢 mobile (caretaker role)
- Route: `/caretaker/home`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: care_home_today, care_home_review, care_home_log (bn + en) — lift copy from `careHome`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] careHome_screen matches design
- [ ] caretaker-scoped data (assigned buildings)
- [ ] all states
- [ ] route `/caretaker/home` + caretaker shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- careHome_test → renders; caretaker-scoped
### Manual QA
1. Log in as caretaker → this screen → correct assigned-building data.

## 13. Acceptance criteria
- [ ] Screen matches `careHome` design; caretaker-scoped; all states.
- [ ] **Screen `careHome` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; assigned-buildings only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Caretaker home: today's visitor activity for assigned buildings, quick links to review + log. Fills EPIC-02 caretaker shell Home placeholder.
