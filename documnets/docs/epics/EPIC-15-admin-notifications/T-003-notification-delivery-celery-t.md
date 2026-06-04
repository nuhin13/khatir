---
id: T-003
epic: EPIC-15
title: Notification delivery Celery task
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-00.T-006]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Notification delivery Celery task

## 1. Feature goal
deliver_notification(notification_id): resolve recipients from audience_filter, fan out to per-recipient per-channel tasks, call NotificationSender per channel (WhatsApp/SMS/email/inapp), create/update NotificationDelivery rows, update counts. Tests (eager, mocked sender).

## 2. Business logic
deliver_notification(notification_id): resolve recipients from audience_filter, fan out to per-recipient per-channel tasks, call NotificationSender per channel (WhatsApp/SMS/email/inapp), create/update NotificationDelivery rows, update counts. Tests (eager, mocked sender).

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant backend files per layer; tests.

## 6–10.
DB: as described. Admin audit on writes. Super+ops role gate. No external services (uses NotificationSender). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation
- [x] Admin audit (EPIC-11 T-002 writer)
- [x] Tests (eager Celery where applicable; mocked sender)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per description
## 13. Acceptance criteria
- [x] Feature works per goal; audited; tests + lint pass.
## 14. Self-review
- [x] Audited; follows admin conventions; Celery eager in tests
### Deviations from spec
None. The audience resolver is duplicated at send time (fails closed/empty rather
than raising) so a stale Beat row never crashes the worker; this is intentional
and documented in `tasks.py`. The fan-out enqueues a `deliver_to_recipient`
sub-task per recipient × channel; in-app/email confirm synchronously (delivered),
remote channels (WhatsApp/SMS) are marked sent and confirmed later by webhook.
### Files touched (actual)
- apps/api/khatir/notifications/tasks.py (deliver_notification + deliver_to_recipient)
- apps/api/khatir/notifications/tests/test_delivery.py (14 tests, eager Celery, mocked sender)
## 15. Notes
deliver_notification(notification_id): resolve recipients from audience_filter, fan out to per-recipient per-channel tasks, call NotificationSender per channel (WhatsApp/SMS/email/inapp), create/update NotificationDelivery rows, update counts. Tests (eager, mocked sender).
