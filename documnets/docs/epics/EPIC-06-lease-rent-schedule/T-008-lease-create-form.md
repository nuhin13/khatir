---
id: T-008
epic: EPIC-06
title: Lease create/edit form
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
- [ ] lease form (tenant, rent, advance, dates, due day)
- [ ] rent defaults from unit; due day from config
- [ ] create + activate actions
- [ ] validation + states
- [ ] route /lease/new + edit; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- lease_form_test → validation; save calls create+activate
### Manual QA
1. From unit → create lease → activate → schedule generated.

## 13. Acceptance criteria
- [ ] Lease form creates + activates; states present; tests + analyze pass.

## 14. Self-review
- [ ] Defaults sensible; tokens; validation
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Prevent activating if unit already has an active lease (backend enforces; surface the error nicely).
