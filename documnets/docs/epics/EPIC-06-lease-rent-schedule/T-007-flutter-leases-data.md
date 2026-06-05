---
id: T-007
epic: EPIC-06
title: Flutter leases data layer
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-008, T-009, T-010]
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
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
- [x] freezed Lease/RentSchedule models
- [x] repo create/activate/terminate/getSchedule/unitLease
- [x] providers
- [x] tests (mocked)
- [x] analyze + test pass

## 12. Test plan
### Automated
- test_lease_repo (create/activate/schedule)
### Manual QA
1. Create + activate via repo.

## 13. Acceptance criteria
- [x] Typed leases data layer; tests + analyze pass.

## 14. Self-review
- [x] Wire schema matches backend; enums aligned
### Deviations from spec
- Provider lifecycle method renamed `update` → `editTerms` to avoid clashing
  with the inherited `AsyncNotifier.update(...)` signature (a real compile
  error otherwise). No external API impact (the data layer has no UI consumers
  yet — T-008/T-009/T-010 wire it).
### Files touched (actual)
- apps/mobile/lib/features/leases/data/models/lease_enums.dart (add)
- apps/mobile/lib/features/leases/data/models/models.dart (+ generated .freezed.dart) (add)
- apps/mobile/lib/features/leases/data/lease_repository.dart (add)
- apps/mobile/lib/features/leases/data/providers.dart (add)
- apps/mobile/lib/core/network/api_endpoints.dart (lease/schedule/unitLease routes)
- apps/mobile/test/leases_repo_test.dart (add)

## 15. Notes for the implementing agent
- Mirror enums.md LeaseStatus/RentScheduleStatus as Dart enums.
