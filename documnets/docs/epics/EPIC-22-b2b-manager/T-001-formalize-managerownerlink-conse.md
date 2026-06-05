---
id: T-001
epic: EPIC-22
title: Formalize ManagerOwnerLink (consent + status + scope)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-01.T-002]
blocks: []
external_services: []
feature_flags: [b2b_manager_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Formalize ManagerOwnerLink (consent + status + scope)

## 1. Feature goal
Extend the ManagerOwnerLink model (created in EPIC-01) with status (pending/active/revoked), consent_record FK, permissions_scope json. A manager's for_user access (EPIC-03 T-002) only includes owners with an active link. Migration + tests.

## 2. Business logic
Extend the ManagerOwnerLink model (created in EPIC-01) with status (pending/active/revoked), consent_record FK, permissions_scope json. A manager's for_user access (EPIC-03 T-002) only includes owners with an active link. Migration + tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/managers/... ; tests.

## 6–10.
DB: as described. Manager-scoped via active ManagerOwnerLink. Audited on writes. No external (notify via EPIC-15). Flag b2b_manager_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Owner-consent gating where applicable (active link only)
- [ ] Audit on writes
- [ ] Tests: happy path + scoping (only active-linked owners)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + active-link scoping
## 13. Acceptance criteria
- [ ] Feature works per goal; consent/scope enforced; audited; tests + lint pass.
## 14. Self-review
- [ ] Only active-linked owners accessible; consent respected
### Deviations from spec
### Files touched (actual)
## 15. Notes
Extend the ManagerOwnerLink model (created in EPIC-01) with status (pending/active/revoked), consent_record FK, permissions_scope json. A manager's for_user access (EPIC-03 T-002) only includes owners with an active link. Migration + tests.
