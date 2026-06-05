---
id: T-003
epic: EPIC-22
title: Manager owner-link endpoints (request + consent)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-15.T-002]
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

# T-003 · Manager owner-link endpoints (request + consent)

## 1. Feature goal
POST /api/v1/manager/owners (request link → notifies owner for consent via EPIC-15). Owner consent endpoint (accept/decline). GET linked owners. Link becomes active only on owner consent. Audited.

## 2. Business logic
POST /api/v1/manager/owners (request link → notifies owner for consent via EPIC-15). Owner consent endpoint (accept/decline). GET linked owners. Link becomes active only on owner consent. Audited.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/managers/... ; tests.

## 6–10.
DB: as described. Manager-scoped via active ManagerOwnerLink. Audited on writes. No external (notify via EPIC-15). Flag b2b_manager_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Owner-consent gating where applicable (active link only)
- [x] Audit on writes
- [x] Tests: happy path + scoping (only active-linked owners)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + active-link scoping
## 13. Acceptance criteria
- [x] Feature works per goal; consent/scope enforced; audited; tests + lint pass.
## 14. Self-review
- [x] Only active-linked owners accessible; consent respected
### Deviations from spec
- Owner notification uses EPIC-15 `compose_notification` with a `specific`
  (single-user) audience on the in-app channel (`admin_user=None`, system send),
  since EPIC-15 exposes no per-user transactional helper.
### Files touched (actual)
- apps/api/khatir/managers/services.py (request_owner_link, respond_to_link)
- apps/api/khatir/managers/serializers.py
- apps/api/khatir/managers/views.py
- apps/api/khatir/managers/urls.py
- apps/api/khatir/managers/flags.py
- apps/api/config/urls.py (mount manager routes)
- apps/api/khatir/managers/tests/test_owner_link_api.py
## 15. Notes
POST /api/v1/manager/owners (request link → notifies owner for consent via EPIC-15). Owner consent endpoint (accept/decline). GET linked owners. Link becomes active only on owner consent. Audited.
