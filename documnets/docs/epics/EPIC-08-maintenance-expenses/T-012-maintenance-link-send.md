---
id: T-012
epic: EPIC-08
title: Maintenance link send (web form)
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-005, EPIC-01.T-004]
blocks: []
external_services: [whatsapp, sms]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-012 · Maintenance link send (web form)

## 1. Feature goal
Let the landlord send a tenant the maintenance web-form link (so the tenant can report issues without the app).

## 2. Business logic
Generate a maintenance token (reuse EPIC-07 token pattern) + send via NotificationSender. Optional endpoint to (re)send.

## 3. What this task DOES
- send_maintenance_link(unit/tenant) + optional endpoint; tests (mocked).

## 5. Files & changes
### Add
- maintenance/messaging.py; tests
### Update
- urls (optional POST send)

## 6. Database changes
None (token stateless or stored).
## 7. API changes
Optional POST /api/v1/units/{id}/maintenance-link.
## 8. UI changes
No UI (landlord triggers from unit/more; can be a later wire).
## 9. External services
WhatsApp/SMS via NotificationSender.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] generate maintenance token (reuse pattern)
- [ ] send via NotificationSender
- [ ] optional send endpoint
- [ ] tests (mocked)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_send_maintenance_link
### Manual QA
1. Send link (dev console) → opens webMaint.

## 13. Acceptance criteria
- [ ] Maintenance link generated + sent; tests + lint pass.

## 14. Self-review
- [ ] Reuses token + NotificationSender
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Generalize EPIC-07 token service for maintenance (purpose field) rather than duplicating.
