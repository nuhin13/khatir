---
id: T-010
epic: EPIC-06
title: Lease list/detail screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-007]
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

# T-010 · Lease list/detail screen

## 1. Feature goal
A list of the landlord's leases and a detail view (rent, dates, status, schedule summary, terminate action).

## 2. Business logic
List active/ended leases; detail shows schedule + status + terminate. Reachable from More or portfolio.

## 3. What this task DOES
- Lease list + detail screens; terminate action; states. Widget test.

## 5. Files & changes
### Add
- features/leases/presentation/screens/{lease_list_screen,lease_detail_screen}.dart; ARB; test
### Update
- router /leases, /lease/:id

## 6. Database changes
None.
## 7. API changes
Consumes /leases, /leases/{id}, schedule, terminate.

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Routes: `/leases`, `/lease/:id`
- List + detail; values from packages/design-tokens
- States: loading/error/empty/data
- i18n keys: `leases_title`, `lease_status_*`, `lease_terminate` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] lease list (scoped)
- [ ] lease detail + schedule summary
- [ ] terminate action
- [ ] states; routes; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- lease_list_test, lease_detail_test
### Manual QA
1. View leases; open one; terminate.

## 13. Acceptance criteria
- [ ] Lease list + detail + terminate; states; tests + analyze pass.

## 14. Self-review
- [ ] Tokens; scoped data
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- If the design folds leases into portfolio/unit rather than a separate list, follow the design; this screen can be lightweight.
