---
id: T-003
epic: EPIC-25
title: Caretaker home + visitor review endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: [gatekeeper_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Caretaker home + visitor review endpoints

## 1. Feature goal
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.

## 2. Business logic
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/gatekeeper/... ; tests.

## 6–10.
DB: as described. Caretaker-scoped to assigned buildings. Audited. No external. Flag gatekeeper_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — home / visitor queue / review endpoints
- [x] Caretaker scope (assigned buildings only) — all 3 endpoints route through `VisitorEntry.objects.for_user` (active assignments only)
- [x] Audit on writes — `visitor.review` written by the service on the state change
- [x] Tests: happy + scoping — `tests/test_caretaker_home_api.py`
- [x] ruff clean (gatekeeper app); makemigrations --check clean (no model change)

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [x] Feature works per goal; scoped; audited; tests + lint pass.
## 14. Self-review
- [x] Assigned-buildings scope (revoked assignments excluded); photo pointer never serialized; thin-view + service + scoped-manager conventions
### Deviations from spec
- Review verb is `visitor.review` (open verb set per `enums.md`); `visitor.log` stays reserved for the gate-side logging endpoint (T-004).
- Caretaker endpoints are flat (`/api/v1/caretaker/...`), not building-nested, since they are scoped to the acting caretaker's active assignments rather than one addressable building.
- Home returns a today summary `{date, counts{total,pending,approved,denied}, recent[≤20]}`; visitor photo is never exposed.
- Re-reviewing an already-decided entry is a `409 conflict` (no silent state flip).
### Files touched (actual)
- apps/api/khatir/gatekeeper/{views,urls,serializers,permissions,services}.py
- apps/api/khatir/gatekeeper/tests/test_caretaker_home_api.py
## 15. Notes
GET /api/v1/caretaker/home (today's activity for assigned buildings), GET /caretaker/visitors (queue), POST /caretaker/visitors/{id}/review (approve/deny). Caretaker-scoped. Audited.
