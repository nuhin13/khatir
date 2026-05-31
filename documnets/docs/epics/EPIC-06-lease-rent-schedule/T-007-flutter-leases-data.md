---
id: T-007
epic: EPIC-06
title: Flutter leases data layer
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-008, T-009, T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Flutter leases data layer

## 1. Feature goal
Typed data layer for leases + schedule (models, repo, providers).

## 2. Business logic
freezed Lease/RentSchedule models; repo create/activate/terminate/getSchedule/unitLease; Riverpod providers.

## 3. What this task DOES
- Models, repository, providers, tests (mocked dio).

## 5. Files & changes
### Add
- features/leases/data/{models,lease_repository,providers}.dart; test

## 6. Database changes
None.
## 7. API changes
Consumes lease + schedule endpoints.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] freezed Lease/RentSchedule models
- [ ] repo create/activate/terminate/getSchedule/unitLease
- [ ] providers
- [ ] tests (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- test_lease_repo (create/activate/schedule)
### Manual QA
1. Create + activate via repo.

## 13. Acceptance criteria
- [ ] Typed leases data layer; tests + analyze pass.

## 14. Self-review
- [ ] Wire schema matches backend; enums aligned
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Mirror enums.md LeaseStatus/RentScheduleStatus as Dart enums.
