---
id: T-001
epic: EPIC-15
title: Notification + Delivery + Template models
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
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

# T-001 · Notification + Delivery + Template models

## 1. Feature goal
Per schema Domain 8. Notification(sender FK AdminUser, audience_type/filter, channels json, title/body bilingual, schedule_type enum now/scheduled/recurring, scheduled_at, status, counts). NotificationDelivery(notification/user/channel/status/timestamps). NotificationTemplate(key unique, trigger_event, channels, bilingual, variables, active). Migrations + admin + factories + tests.

## 2. Business logic
Per schema Domain 8. Notification(sender FK AdminUser, audience_type/filter, channels json, title/body bilingual, schedule_type enum now/scheduled/recurring, scheduled_at, status, counts). NotificationDelivery(notification/user/channel/status/timestamps). NotificationTemplate(key unique, trigger_event, channels, bilingual, variables, active). Migrations + admin + factories + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant backend files per layer; tests.

## 6–10.
DB: as described. Admin audit on writes. Super+ops role gate. No external services (uses NotificationSender). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation
- [ ] Admin audit (EPIC-11 T-002 writer)
- [ ] Tests (eager Celery where applicable; mocked sender)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per description
## 13. Acceptance criteria
- [ ] Feature works per goal; audited; tests + lint pass.
## 14. Self-review
- [ ] Audited; follows admin conventions; Celery eager in tests
### Deviations from spec
### Files touched (actual)
## 15. Notes
Per schema Domain 8. Notification(sender FK AdminUser, audience_type/filter, channels json, title/body bilingual, schedule_type enum now/scheduled/recurring, scheduled_at, status, counts). NotificationDelivery(notification/user/channel/status/timestamps). NotificationTemplate(key unique, trigger_event, channels, bilingual, variables, active). Migrations + admin + factories + tests.
