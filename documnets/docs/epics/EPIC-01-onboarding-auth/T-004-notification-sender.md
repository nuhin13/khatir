---
id: T-004
epic: EPIC-01
title: NotificationSender interface + console/WhatsApp/SMS impls
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-005]
external_services: [whatsapp, sms]
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
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
- [x] NotificationSender ABC (generic send) — `khatir/messaging/senders.py`
- [x] ConsoleSender logs message + code (dev)
- [x] WhatsAppSender (HTTP, creds from env, errors clearly if unset)
- [x] SmsSender (HTTP, creds from env)
- [x] Sender selector: dev→console; else primary channel + SMS fallback — `khatir/messaging/factory.py`
- [x] send_otp(phone, code) bilingual message — `khatir/accounts/notifications.py`
- [x] Tests: console logs; WhatsApp/SMS mocked; fallback path
- [x] No secrets logged (global PII filter masks codes/phones)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_console_sender → message + code logged (dev)
- test_whatsapp_sender → mocked HTTP called with correct payload
- test_sms_fallback → WhatsApp failure falls back to SMS
- test_missing_creds → clear configuration error
### Manual QA
1. `DJANGO_ENV=dev`, trigger send_otp → code appears in logs, no external call.

## 13. Acceptance criteria
- [x] Generic sender interface with 3 impls.
- [x] Dev uses console; prod uses configured channel + fallback.
- [x] Buildable/testable with no WhatsApp/SMS account.
- [x] Tests + lint pass.

## 14. Self-review
- [x] Interface is generic (not OTP-locked) for EPIC-15 reuse
- [x] No secrets logged; creds from env
- [x] Fallback works
### Deviations from spec
- **Module placement:** put the reusable layer in a new `khatir/messaging/`
  package (interface + 3 senders + factory) rather than `accounts/senders.py`,
  per §15's "keep it reusable so EPIC-15 extends rather than duplicates". The
  OTP-specific `send_otp` helper lives in `khatir/accounts/notifications.py`
  (next to the OTP service), keeping the messaging layer OTP-agnostic. EPIC-15
  should extend `khatir/messaging/` (register channels in the factory
  `_REGISTRY`, add senders), not the accounts helper.
- **`khatir.messaging` is a plain package, not an INSTALLED_APP** — it has no
  models/migrations, so it needs no AppConfig.
- **HTTP client:** used the stdlib (`urllib.request`) in `_post_json` rather
  than adding an httpx/requests dependency (none was present), so the app stays
  buildable with no new deps. Tests patch `_post_json` — no network.
- **Sender selection** is exposed as `get_sender(channel=None)` (factory) plus
  `send_with_fallback(recipient, message)` for the configured-channel + fallback
  path. `ConsoleSender.channel` is `Channel.INAPP` (no `console` enum member).
### Files touched (actual)
- Add: `apps/api/khatir/messaging/__init__.py`
- Add: `apps/api/khatir/messaging/senders.py` (NotificationSender ABC + 3 impls)
- Add: `apps/api/khatir/messaging/factory.py` (get_sender + send_with_fallback)
- Add: `apps/api/khatir/accounts/notifications.py` (send_otp helper)
- Add: `apps/api/khatir/accounts/tests/test_senders.py` (15 tests)
- Update: `apps/api/config/settings/base.py` (WHATSAPP_*/SMS_* settings)
- Verified: `.env.example` already carries WHATSAPP_*/SMS_* (no change needed)

## 15. Notes for the implementing agent
- OTP message (bn): "আপনার খাতির ভেরিফিকেশন কোড: {code}। কোডটি {minutes} মিনিট পর্যন্ত বৈধ।" + an English line. Keep it short (SMS length).
- Put this module somewhere reusable (`khatir/messaging/`) since EPIC-15 builds the full system on top — flag in self-review where you placed it so EPIC-15 extends rather than duplicates.
