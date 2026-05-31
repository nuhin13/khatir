---
id: T-006
epic: EPIC-15
title: Retrofit EPIC-07 reminders to use template system
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-005, EPIC-07.T-008]
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

# T-006 · Retrofit EPIC-07 reminders to use template system

## 1. Feature goal
EPIC-07 T-008 reminder task builds message text directly. Replace with get_template('rent_reminder_due').render(variables). Keeps EPIC-07 behavior identical but uses the admin-editable template. Tests unchanged behavior.

## 2. Business logic
EPIC-07 T-008 reminder task builds message text directly. Replace with get_template('rent_reminder_due').render(variables). Keeps EPIC-07 behavior identical but uses the admin-editable template. Tests unchanged behavior.

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
EPIC-07 T-008 reminder task builds message text directly. Replace with get_template('rent_reminder_due').render(variables). Keeps EPIC-07 behavior identical but uses the admin-editable template. Tests unchanged behavior.
