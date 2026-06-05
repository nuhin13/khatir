---
id: T-008
epic: EPIC-06
title: Lease create/edit form
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Lease create/edit form

## 1. Feature goal
A form to create/edit a lease (select tenant, set rent, advance, start/end, due day) and activate it.

## 2. Business logic
Launched from unit detail (unit context). Tenant picker (unit's tenant or pick), rent (default from unit), advance, dates, due day (default config). Save → create draft → optional activate.

## 3. What this task DOES
- Lease form screen + validation; create + activate actions; states. Widget test.

## 5. Files & changes
### Add
- features/leases/presentation/screens/lease_form_screen.dart; ARB; test
### Update
- router /lease/new (and /lease/:id/edit)

## 6. Database changes
None.
## 7. API changes
Consumes POST /leases + activate.

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/lease/new`, `/lease/:id/edit`
- Lease form; values from packages/design-tokens
- States: data, validation, saving, error
- Navigation: launched from unit detail; save → back to unit (lease section shows)
- i18n keys: `lease_rent`, `lease_advance`, `lease_start`, `lease_end`, `lease_due_day`, `lease_save`, `lease_activate` (bn + en)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] lease form (tenant, rent, advance, dates, due day)
- [x] rent defaults from unit; due day from config
- [x] create + activate actions
- [x] validation + states
- [x] route /lease/new + edit; ARB bn + en; widget test
- [x] analyze + test pass (lease_form: 6/6; analyze info-level lints are pre-existing repo baseline in unrelated files, none from this screen)

## 12. Test plan
### Automated
- lease_form_test → validation; save calls create+activate
### Manual QA
1. From unit → create lease → activate → schedule generated.

## 13. Acceptance criteria
- [x] Lease form creates + activates; states present; tests + analyze pass.

## 14. Self-review
- [x] Defaults sensible; tokens; validation
### Deviations from spec
- None. The unit-already-has-active-lease guard (§15) is surfaced as a friendly
  `lease_active_exists` snackbar when the backend returns 400/409 on activate.
- The lease_form_screen.dart + lease_form_test.dart + router routes + ARB keys
  were authored during the prior EPIC-06 build pass and landed in the T-010 batch
  commit (220ddfe); this task closes the finish protocol (status/board) after
  re-verifying the gate.
### Files touched (actual)
- apps/mobile/lib/features/leases/presentation/screens/lease_form_screen.dart
- apps/mobile/lib/core/router/app_router.dart (/lease/new + /lease/:id/edit)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb (lease_* keys)
- apps/mobile/test/lease_form_test.dart

## 15. Notes for the implementing agent
- Prevent activating if unit already has an active lease (backend enforces; surface the error nicely).
