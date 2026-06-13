---
id: T-009
epic: EPIC-15
title: Seed notifications config
layer: backend
size: XS
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
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

# T-009 · Seed notifications config

## 1. Feature goal
Seed whatsapp_cost_per_message (Decimal), sms_cost_per_message, email_cost_per_message SystemConfig. Used for cost preview in composer.

## 2. Business logic
Seed whatsapp_cost_per_message (Decimal), sms_cost_per_message, email_cost_per_message SystemConfig. Used for cost preview in composer.

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
Seed whatsapp_cost_per_message (Decimal), sms_cost_per_message, email_cost_per_message SystemConfig. Used for cost preview in composer.
