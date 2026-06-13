---
id: T-010
epic: EPIC-06
title: Lease list/detail screen
layer: mobile
size: M
status: done
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
- [x] lease list (scoped)
- [x] lease detail + schedule summary
- [x] terminate action
- [x] states; routes; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- lease_list_test, lease_detail_test
### Manual QA
1. View leases; open one; terminate.

## 13. Acceptance criteria
- [x] Lease list + detail + terminate; states; tests + analyze pass.

## 14. Self-review
- [x] Tokens; scoped data
### Deviations from spec
- Added an optional `grouped` parameter to `BanglaNumerals.format` (default
  `true`, preserving existing behaviour) so date parts (year/month/day) can be
  formatted without a thousands separator. The lease list screen (added in a
  prior partial run of this task) already called `format(..., grouped: false)`;
  this makes that call compile and keeps date rendering correct.
- Detail screen reuses the list screen's `leaseStatusLabel` / `termRange`
  helpers (shared, not duplicated). The terminate confirm button reuses the
  `lease_terminate` string (no separate confirm-label key exists in the ARB).
### Files touched (actual)
- apps/mobile/lib/features/leases/presentation/screens/lease_detail_screen.dart (add)
- apps/mobile/lib/features/leases/presentation/screens/lease_list_screen.dart (string-interpolation cleanup; part of T-010)
- apps/mobile/lib/core/i18n/bangla_numerals.dart (add optional `grouped` param)
- apps/mobile/lib/core/router/app_router.dart (add `/leases` + `/lease/:id` routes)
- apps/mobile/test/lease_list_test.dart (add)
- apps/mobile/test/lease_detail_test.dart (add)
- l10n ARB keys + generated localizations (already present from prior partial run)

## 15. Notes for the implementing agent
- If the design folds leases into portfolio/unit rather than a separate list, follow the design; this screen can be lightweight.
