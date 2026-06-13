---
id: T-004
epic: EPIC-19
title: Tenant maintenance report endpoint (reuse EPIC-08)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-08.T-002]
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

# T-004 · Tenant maintenance report endpoint (reuse EPIC-08)

## 1. Feature goal
POST /api/v1/me/maintenance — report maintenance in-app, creating a MaintenanceRequest (reuse EPIC-08 logic). Tenant-scoped to their unit.

## 2. Business logic
POST /api/v1/me/maintenance — report maintenance in-app, creating a MaintenanceRequest (reuse EPIC-08 logic). Tenant-scoped to their unit.

## 3. What this task DOES
See feature goal. Reuses existing pipelines (EPIC-07/08) — does NOT duplicate logic.

## 5. Files & changes
### Add/Update
- tenants/me_views.py or per-domain /me endpoints; tests.

## 6–10.
DB: reads/writes via existing models. Tenant-scoped. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core endpoint per goal
- [x] tenant_for_user scoping (own only)
- [x] reuse existing pipeline (no duplication)
- [x] Tests: works + scoped + others' blocked
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [x] Endpoint works, tenant-scoped, reuses pipeline; tests + lint pass.
## 14. Self-review
- [x] No duplicated proof/maintenance logic; strict scope
### Deviations from spec
- `POST /api/v1/me/maintenance` is a plain `APIView` (`MeMaintenanceView`) gated by
  `IsLinkedTenant`, mounted alongside the other `/me/*` endpoints in
  `tenants/urls.py`. The unit and active lease are resolved server-side via the
  T-001 `active_lease_for_user` helper and never trusted from the client, so the
  request body carries no `unit_id`: a tenant can only ever report against their
  own unit, and a tenant with no active lease gets a 404 (P0 scope contract).
- It feeds the **same** `khatir.maintenance.services.create_maintenance_request`
  pipeline as the landlord create surface (audit + `open` status) — no
  maintenance logic is duplicated. A small write serializer
  (`MeMaintenanceCreateSerializer`: `description`, optional `category` defaulting
  to `OTHER`, optional `photo_ref`) was added since the maintenance app's
  serializers did not expose a tenant-facing create body.
### Files touched (actual)
- Update: `apps/api/khatir/tenants/me_views.py` (`MeMaintenanceView`)
- Update: `apps/api/khatir/tenants/me_serializers.py` (`MeMaintenanceCreateSerializer`)
- Update: `apps/api/khatir/tenants/urls.py` (`me/maintenance` route)
- Update: `apps/api/khatir/tenants/tests/test_me_endpoints.py` (maintenance tests)
## 15. Notes
POST /api/v1/me/maintenance — report maintenance in-app, creating a MaintenanceRequest (reuse EPIC-08 logic). Tenant-scoped to their unit.
