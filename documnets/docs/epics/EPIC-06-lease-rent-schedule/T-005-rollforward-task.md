---
id: T-005
epic: EPIC-06
title: Monthly roll-forward + overdue Celery task
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, EPIC-00.T-006]
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

# T-005 · Monthly roll-forward + overdue Celery task

## 1. Feature goal
A scheduled task that extends each active lease's schedule forward monthly and flags overdue periods past their grace window.

## 2. Business logic
Celery Beat (daily/monthly): for each active lease, ensure schedule covers the horizon (T-002 generate idempotent); mark pending schedules past due_date+grace as overdue. Grace from config.

## 3. What this task DOES
- Beat task `roll_schedules_and_flag_overdue`; registers a Beat entry; tests (eager) for roll-forward + overdue flagging.

## 5. Files & changes
### Add
- leases/tasks.py, tests/test_rollforward.py
### Update
- celery beat schedule

## 6. Database changes
Updates schedule rows (new periods, overdue status).
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] roll-forward task (idempotent generate to horizon)
- [ ] overdue flagging past due_date + grace
- [ ] Beat schedule entry
- [ ] Tests (eager): roll-forward, overdue
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_rollforward_extends, test_overdue_flagged_after_grace
### Manual QA
1. Run task → new periods + overdue flags.

## 13. Acceptance criteria
- [ ] Roll-forward + overdue flagging correct + idempotent; tests + lint pass.

## 14. Self-review
- [ ] Idempotent; grace from config; UTC
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuses T-002 generate (idempotent). Overdue grace = rent_overdue_grace_days config.
