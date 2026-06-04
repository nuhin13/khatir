---
id: T-008
epic: EPIC-07
title: Reminder cadence Celery task
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-004, EPIC-00.T-006]
blocks: []
external_services: [whatsapp, sms]
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Reminder cadence Celery task

## 1. Feature goal
Automatically remind tenants about unpaid rent requests on a configurable cadence.

## 2. Business logic
Beat task: for sent-but-unpaid requests past cadence thresholds (rent_reminder_cadence_hours, e.g. [24,48]), resend the link (T-004). Stop after max reminders. Don't spam.

## 3. What this task DOES
- reminder task + Beat entry; cadence from config; tests (eager).

## 5. Files & changes
### Add
- rent/tasks.py, tests/test_reminders.py
### Update
- beat schedule

## 6. Database changes
Tracks reminders sent (count/last).
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
WhatsApp/SMS via T-004.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] reminder task resends per cadence
- [ ] stop after max; no spam
- [ ] cadence from config
- [ ] Beat entry
- [ ] Tests (eager): reminder fires at threshold, stops after max
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_reminder_at_24h, test_stops_after_max
### Manual QA
1. Simulate overdue → reminder logged.

## 13. Acceptance criteria
- [ ] Reminders fire on cadence + stop after max; tests + lint pass.

## 14. Self-review
- [ ] Cadence from config; idempotent per window
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Track last_reminded_at + reminder_count on RentRequest (add fields if needed via migration). Reuse T-004 send.
