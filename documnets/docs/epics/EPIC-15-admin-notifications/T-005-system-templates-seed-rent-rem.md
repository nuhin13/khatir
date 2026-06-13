---
id: T-005
epic: EPIC-15
title: System templates seed (rent-reminder, receipt, welcome)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-001]
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

# T-005 · System templates seed (rent-reminder, receipt, welcome)

## 1. Feature goal
Seed NotificationTemplate rows: rent_reminder_due (trigger=rent_due, channels=whatsapp+sms, bilingual), rent_receipt_generated (trigger=payment_verified), welcome_new_user (trigger=user_created). Idempotent. Tests.

## 2. Business logic
Seed NotificationTemplate rows: rent_reminder_due (trigger=rent_due, channels=whatsapp+sms, bilingual), rent_receipt_generated (trigger=payment_verified), welcome_new_user (trigger=user_created). Idempotent. Tests.

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
Seed NotificationTemplate rows: rent_reminder_due (trigger=rent_due, channels=whatsapp+sms, bilingual), rent_receipt_generated (trigger=payment_verified), welcome_new_user (trigger=user_created). Idempotent. Tests.
