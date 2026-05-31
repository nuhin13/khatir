---
id: T-011
epic: EPIC-07
title: Flutter rent-request screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-010]
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

# T-011 · Flutter rent-request screen

## 1. Feature goal
Let the landlord request rent for a due period and send the link (WhatsApp/SMS), with an option to mark cash received.

## 2. Business logic
Per `rentReq` design. Shows amount/period; "Send WhatsApp link" + "Mark received (cash)". On send → request created + link sent. Routes to verify queue.

## 3. What this task DOES
- rent_request_screen matching `rentReq`; send + mark-received actions; states. Widget test.

## 5. Files & changes
### Add
- features/rent/presentation/screens/rent_request_screen.dart; ARB; test
### Update
- router /rent/request; unit/home rent CTAs wire here

## 6. Database changes
None.
## 7. API changes
Consumes create + send (+ mark-received).

## 8. UI changes
- **Design source:** screen `rentReq` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('rentReq')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/rent/request`
- Translate request UI (amount, send link, mark received); values from packages/design-tokens
- States: data, sending, error
- Navigation: send → verify queue; mark-received → receipt
- i18n keys: `rent_request_amount`, `rent_send_whatsapp`, `rent_mark_received` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] rent_request_screen matches design
- [ ] send link action (create + send)
- [ ] mark-received action
- [ ] states; route; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- rent_request_test → send creates+sends; mark-received → receipt
### Manual QA
1. Request rent → link sent (dev console) → appears in verify queue.

## 13. Acceptance criteria
- [ ] Request screen matches design; send + cash paths work.
- [ ] **Screen `rentReq` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Entry from unit detail (active lease) + home late-payers (T-014).
