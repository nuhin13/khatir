---
id: T-002
epic: EPIC-15
title: Notification compose + schedule service
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-01.T-004]
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

# T-002 · Notification compose + schedule service

## 1. Feature goal
compose_notification(admin_user, audience, channels, content, schedule): validate audience (all/role/segment/specific IDs), resolve reach count, estimate cost (from config: per-message cost per channel), create Notification record, enqueue delivery task if now or schedule via Celery Beat if future. Reuses EPIC-01 NotificationSender. Tests.

## 2. Business logic
compose_notification(admin_user, audience, channels, content, schedule): validate audience (all/role/segment/specific IDs), resolve reach count, estimate cost (from config: per-message cost per channel), create Notification record, enqueue delivery task if now or schedule via Celery Beat if future. Reuses EPIC-01 NotificationSender. Tests.

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
compose_notification(admin_user, audience, channels, content, schedule): validate audience (all/role/segment/specific IDs), resolve reach count, estimate cost (from config: per-message cost per channel), create Notification record, enqueue delivery task if now or schedule via Celery Beat if future. Reuses EPIC-01 NotificationSender. Tests.
