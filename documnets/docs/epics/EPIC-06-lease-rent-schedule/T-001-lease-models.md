---
id: T-001
epic: EPIC-06
title: Lease + RentSchedule models, enums, migration
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-04.T-001, EPIC-03.T-001]
blocks: [T-002, T-003]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Lease + RentSchedule models, enums, migration

## 1. Feature goal
Create the `leases` app with `Lease` and `RentSchedule` models.

## 2. Business logic
Per schema Domain 4. Lease(unit PROTECT, tenant PROTECT, landlord, start/end, rent Decimal, advance Decimal, status). RentSchedule(lease CASCADE, period 'YYYY-MM', due_day, due_date, amount, status). Indexes per epic. Soft-delete + timestamps.

## 3. What this task DOES
- leases app; both models; LeaseStatus + RentScheduleStatus enums; indexes; admin; migration; factories + tests.

## 5. Files & changes
### Add
- khatir/leases/{__init__,apps,models,enums,admin}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
Creates leases_lease, leases_rentschedule. Reversible.
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
- [ ] Lease model (FKs, money Decimal, status enum, soft-delete)
- [ ] RentSchedule model (period, due_day, due_date, amount, status)
- [ ] enums match enums.md
- [ ] indexes
- [ ] admin + migration reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_lease_create, test_schedule_create, money_is_decimal
### Manual QA
1. Create lease in admin.

## 13. Acceptance criteria
- [ ] Models per schema; migration clean; tests + lint pass.

## 14. Self-review
- [ ] Money Decimal; enums match; soft-delete
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- unit + tenant are PROTECT (can't delete while leased). period is 'YYYY-MM' string.
