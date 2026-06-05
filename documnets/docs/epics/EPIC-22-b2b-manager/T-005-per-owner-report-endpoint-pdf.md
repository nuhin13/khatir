---
id: T-005
epic: EPIC-22
title: Per-owner report endpoint (PDF)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-05.T-003]
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

# T-005 · Per-owner report endpoint (PDF)

## 1. Feature goal
GET /api/v1/manager/owners/{id}/report — generate a per-owner summary report (collection, occupancy, expenses) as PDF (reuse EPIC-05). Only for active-linked owners. Audited.

## 2. Business logic
GET /api/v1/manager/owners/{id}/report — generate a per-owner summary report (collection, occupancy, expenses) as PDF (reuse EPIC-05). Only for active-linked owners. Audited.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/managers/... ; tests.

## 6–10.
DB: as described. Manager-scoped via active ManagerOwnerLink. Audited on writes. No external (notify via EPIC-15). Flag b2b_manager_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `ManagerOwnerReportView` (GET /manager/owners/{id}/report) returns `application/pdf`; reuses EPIC-09 `get_dashboard` (via `report.build_owner_report`) + EPIC-05 `_render_pdf`.
- [x] Owner-consent gating where applicable (active link only) — resolves owner only through `ManagerOwnerLink.objects.for_manager(m).active()`; any other id → 404.
- [x] Audit on writes — manager access logged as `manager.owner_report.read` (sensitive-data read is the auditable event).
- [x] Tests: happy path + scoping (only active-linked owners) — `tests/test_owner_report_api.py` (PDF, determinism, audit, pending/revoked/other-manager/unknown → 404, months, role, auth, flag).
- [x] ruff clean (gate); no model changes so `makemigrations --check` reports no changes.

## 12. Test plan
### Automated
- Core tests + active-link scoping
## 13. Acceptance criteria
- [x] Feature works per goal; consent/scope enforced; audited; tests + lint pass.
## 14. Self-review
- [x] Only active-linked owners accessible; consent respected
### Deviations from spec
- Endpoint returns the PDF inline (`application/pdf`) rather than a signed-URL JSON (the per-owner report is a transient render, not a stored artifact like the DMP form), matching the task goal "generate ... as PDF".
### Files touched (actual)
- `apps/api/khatir/managers/report.py` (report builder — reuses EPIC-09 selectors + EPIC-05 PDF primitive)
- `apps/api/khatir/managers/views.py` (`ManagerOwnerReportView`)
- `apps/api/khatir/managers/urls.py` (route `manager/owners/<int:owner_id>/report`)
- `apps/api/khatir/managers/tests/test_owner_report_api.py` (tests)
## 15. Notes
GET /api/v1/manager/owners/{id}/report — generate a per-owner summary report (collection, occupancy, expenses) as PDF (reuse EPIC-05). Only for active-linked owners. Audited.
