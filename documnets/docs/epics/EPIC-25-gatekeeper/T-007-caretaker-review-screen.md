---
id: T-007
epic: EPIC-25
title: Caretaker review screen
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

# T-007 · Caretaker review screen

## 1. Feature goal
Visitor review queue: pending visitor entries (name, purpose, photo) with approve/deny actions.

## 2. Business logic
Visitor review queue: pending visitor entries (name, purpose, photo) with approve/deny actions. Per `careReview` design.

## 3. What this task DOES
- careReview_screen matching the `careReview` design; caretaker-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/gatekeeper/presentation/screens/careReview_screen.dart; ARB; test
### Update
- router `/caretaker/review`; caretaker shell wiring

## 6–10.
No DB; consumes caretaker endpoints; mobile 🟢 (caretaker role); flag gatekeeper_enabled.

## 8. UI changes
- **Design source:** screen `careReview` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('careReview')`)
- Surface: mobile · **Lane:** 🟢 mobile (caretaker role)
- Route: `/caretaker/review`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: care_review_visitor, care_review_approve, care_review_deny, care_review_empty (bn + en) — lift copy from `careReview`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] careReview_screen matches design
- [ ] caretaker-scoped data (assigned buildings)
- [ ] all states
- [ ] route `/caretaker/review` + caretaker shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- careReview_test → renders; caretaker-scoped
### Manual QA
1. Log in as caretaker → this screen → correct assigned-building data.

## 13. Acceptance criteria
- [ ] Screen matches `careReview` design; caretaker-scoped; all states.
- [ ] **Screen `careReview` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; assigned-buildings only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Visitor review queue: pending visitor entries (name, purpose, photo) with approve/deny actions.
