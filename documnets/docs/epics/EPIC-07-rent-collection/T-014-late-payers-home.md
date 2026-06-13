---
id: T-014
epic: EPIC-07
title: Late-payers + rent status on home (fill EPIC-03)
layer: mobile
size: S
status: done
preferred_agent: claude-code
depends_on: [T-010, EPIC-03.T-009]
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

# T-014 · Late-payers + rent status on home (fill EPIC-03)

## 1. Feature goal
Fill the home screen's late-payers / rent-status region (placeholder from EPIC-03 T-009) with real overdue tenants + quick "request rent" actions.

## 2. Business logic
Uses rent status (overdue schedules) to list late payers with a one-tap request-rent. Replaces the EPIC-03 home placeholder.

## 3. What this task DOES
- Late-payers widget on home (overdue list + quick request); replace placeholder; states. Widget test.

## 5. Files & changes
### Add
- features/rent/presentation/widgets/late_payers_section.dart; test
### Update
- EPIC-03 landlord_home_screen.dart — replace late-payer placeholder

## 6. Database changes
None.
## 7. API changes
Consumes rent status / overdue.

## 8. UI changes
- **Design source:** `home` late-payers region — `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('home')`
- Surface: mobile · **Lane:** 🟢 mobile
- Late-payers section on `/landlord/home`
- States: loading/empty (all paid)/data
- Navigation: quick request → /rent/request
- i18n keys: `home_late_payers`, `home_all_paid`, `home_quick_request` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] late-payers section (overdue list + quick request)
- [x] replaces EPIC-03 home placeholder (remove TODO)
- [x] empty state (all paid)
- [x] widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- late_payers_test → lists overdue; quick-request routes
### Manual QA
1. Overdue tenant shows on home → quick request → link sent.

## 13. Acceptance criteria
- [x] Home shows real late-payers; EPIC-03 placeholder removed.
- [x] Test + analyze pass.

## 14. Self-review
- [x] EPIC-03 TODO removed; tokens
### Deviations from spec
- "Late payers" are derived from the committed T-010 rent-request queue
  (unpaid = `sent` / `proof_submitted`); there is no dedicated overdue endpoint
  yet, so the section reads `rentQueueProvider`. Rows show amount · period (the
  rent-request payload does not carry tenant name / unit labels — those are not
  on `RentRequestSerializer`), with a per-row "Ask" pill routing to
  `/rent/request?lease=…&amount=…&period=…`.
- Only the late-payer portion of the EPIC-03 `_CollectionCard` placeholder is
  replaced; the collected/expected amount + progress chart stay deferred to
  EPIC-09 (per §15).
### Files touched (actual)
- Add: apps/mobile/lib/features/rent/presentation/widgets/late_payers_section.dart
- Update: apps/mobile/lib/features/properties/presentation/screens/landlord_home_screen.dart
- Update: apps/mobile/lib/l10n/app_en.arb, app_bn.arb (home_late_payers,
  home_late_payers_one, home_all_paid, home_quick_request)
- Test: apps/mobile/test/landlord_home_test.dart (3 new late-payers cases)

## 15. Notes for the implementing agent
- Closes the EPIC-03→07 home seam. Charts region still belongs to EPIC-09.
