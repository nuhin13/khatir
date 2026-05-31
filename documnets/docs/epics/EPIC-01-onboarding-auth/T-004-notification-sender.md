---
id: T-004
epic: EPIC-01
title: NotificationSender interface + console/WhatsApp/SMS impls
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-005]
external_services: [whatsapp, sms]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · NotificationSender interface + console/WhatsApp/SMS impls

## 1. Feature goal
Create a channel-agnostic `NotificationSender` interface with three implementations — console (dev), WhatsApp, SMS — so OTP (and later all messaging) can be sent without the rest of the code knowing or caring which channel, and so the app is fully buildable before WhatsApp approval.

## 2. Business logic
- Primary channel from `auth_primary_channel` SystemConfig (default `whatsapp`), with SMS fallback.
- Dev environment uses the **console** sender (logs the message + OTP) so no external account is needed.
- WhatsApp/SMS implementations read credentials from env (`WHATSAPP_*`, `SMS_*`); if unset, they raise a clear configuration error (caught upstream) rather than failing silently.
- This is the seed of the broader notifications system (EPIC-15 will extend it); keep the interface generic (send a templated message to a recipient), not OTP-specific.

## 3. What this task DOES
- `accounts/senders.py` (or `khatir/notifications_base/`): `NotificationSender` ABC with `send(recipient, message, *, channel)`.
- `ConsoleSender` (logs), `WhatsAppSender` (calls WhatsApp API), `SmsSender` (calls SMS gateway).
- A factory/selector that picks the sender by env (`DJANGO_ENV=dev` → console) + configured primary channel, with fallback.
- An `send_otp(phone, code)` helper that formats the bilingual OTP message and dispatches.
- Tests with mocked HTTP for WhatsApp/SMS; console sender asserted to log.

## 4. What this task does NOT do
- Does not build the full notifications/admin system (EPIC-15).
- Does not implement delivery tracking tables (EPIC-15).

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/senders.py` (or a small `khatir/messaging/` module — keep it reusable)
- `apps/api/khatir/accounts/tests/test_senders.py`
### Update
- `.env.example` already has WHATSAPP_*/SMS_* (verify)
### Delete
- none

## 6. Database changes
No DB changes (delivery tracking is EPIC-15).

## 7. API changes
No endpoints (internal).

## 8. UI changes
No UI changes.

## 9. External services
- WhatsApp Business API (`WHATSAPP_API_URL`, `WHATSAPP_API_TOKEN`, `WHATSAPP_PHONE_ID`).
- SMS gateway (`SMS_GATEWAY_URL`, `SMS_GATEWAY_KEY`).
- **Dev:** neither needed — console sender used.

## 10. Feature flags
None (channel is config).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] NotificationSender ABC (generic send)
- [ ] ConsoleSender logs message + code (dev)
- [ ] WhatsAppSender (HTTP, creds from env, errors clearly if unset)
- [ ] SmsSender (HTTP, creds from env)
- [ ] Sender selector: dev→console; else primary channel + SMS fallback
- [ ] send_otp(phone, code) bilingual message
- [ ] Tests: console logs; WhatsApp/SMS mocked; fallback path
- [ ] No secrets logged
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_console_sender → message + code logged (dev)
- test_whatsapp_sender → mocked HTTP called with correct payload
- test_sms_fallback → WhatsApp failure falls back to SMS
- test_missing_creds → clear configuration error
### Manual QA
1. `DJANGO_ENV=dev`, trigger send_otp → code appears in logs, no external call.

## 13. Acceptance criteria
- [ ] Generic sender interface with 3 impls.
- [ ] Dev uses console; prod uses configured channel + fallback.
- [ ] Buildable/testable with no WhatsApp/SMS account.
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Interface is generic (not OTP-locked) for EPIC-15 reuse
- [ ] No secrets logged; creds from env
- [ ] Fallback works
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- OTP message (bn): "আপনার খাতির ভেরিফিকেশন কোড: {code}। কোডটি {minutes} মিনিট পর্যন্ত বৈধ।" + an English line. Keep it short (SMS length).
- Put this module somewhere reusable (`khatir/messaging/`) since EPIC-15 builds the full system on top — flag in self-review where you placed it so EPIC-15 extends rather than duplicates.
