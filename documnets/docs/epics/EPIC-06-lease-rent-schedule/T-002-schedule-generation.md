---
id: T-002
epic: EPIC-06
title: Rent-schedule generation service
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-004, T-005]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Rent-schedule generation service

## 1. Feature goal
Given an active lease, generate its monthly RentSchedule rows from start through a horizon (e.g. current month + N ahead), with correct due dates.

## 2. Business logic
Pure function: for each month in range, create a schedule row (period, due_day clamped to month length, due_date, amount=lease.rent, status=pending). Idempotent (don't duplicate existing periods). Due day from lease or default config.

## 3. What this task DOES
- `leases/scheduling.py`: generate_schedule(lease, through) idempotent. Due-day clamping (e.g. 31→month end). Tests incl. month-end + partial first month.

## 5. Files & changes
### Add
- leases/scheduling.py, tests/test_scheduling.py

## 6. Database changes
Creates schedule rows (called on activate / roll-forward).
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
- [ ] generate_schedule pure + idempotent
- [ ] due_day clamps to month length
- [ ] amount = lease.rent
- [ ] no duplicate periods
- [ ] Tests: normal, month-end clamp, idempotency, partial first month
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_generate_months, test_due_day_clamp_feb, test_idempotent
### Manual QA
1. Activate a lease → schedule rows appear.

## 13. Acceptance criteria
- [ ] Correct, idempotent schedule generation; tests + lint pass.

## 14. Self-review
- [ ] Idempotent; UTC dates; clamps correctly
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Keep it pure for testability. due_day 31 in Feb → 28/29. Roll-forward (T-005) calls this monthly.
