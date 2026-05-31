---
id: T-004
epic: EPIC-07
title: WhatsApp/SMS rent-link send (NotificationSender)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, EPIC-01.T-004]
blocks: [T-008]
external_services: [whatsapp, sms]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · WhatsApp/SMS rent-link send (NotificationSender)

## 1. Feature goal
Send the rent-request web link to the tenant via WhatsApp (SMS fallback), reusing the EPIC-01 NotificationSender.

## 2. Business logic
Build the public URL (/r/{token}) + bilingual message; send via NotificationSender (console in dev). On success set status sent + sent_at + sent_via. Failure → fallback channel.

## 3. What this task DOES
- send_rent_link(rent_request) service; wire into create (or explicit send endpoint); tests (mocked sender, fallback).

## 5. Files & changes
### Add
- rent/messaging.py, tests/test_send.py
### Update
- rent/services.py (call on create or via POST /{id}/send)

## 6. Database changes
Updates request status/sent fields.
## 7. API changes
Optionally POST /api/v1/rent-requests/{id}/send.

## 8. UI changes
No UI.
## 9. External services
WhatsApp + SMS (via NotificationSender; console dev).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] build /r/{token} URL + bilingual message
- [ ] send via NotificationSender (console dev)
- [ ] status→sent on success; fallback on failure
- [ ] Tests (mocked, fallback path)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_send_whatsapp, test_sms_fallback, test_status_sent
### Manual QA
1. Create+send (dev) → link logged to console.

## 13. Acceptance criteria
- [ ] Link sent via WhatsApp/SMS (console dev); status updated; tests + lint pass.

## 14. Self-review
- [ ] Reuses NotificationSender; no secret logged
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse EPIC-01 NotificationSender (don't build new). EPIC-15 will template these messages; keep copy in one place.
