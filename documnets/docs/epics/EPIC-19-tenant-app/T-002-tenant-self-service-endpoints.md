---
id: T-002
epic: EPIC-19
title: Tenant self-service endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-06.T-004, EPIC-07.T-001]
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

# T-002 · Tenant self-service endpoints

## 1. Feature goal
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.

## 2. Business logic
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.

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
- Receipts are exposed as confirmed `rent.Payment` rows (the rent domain has no
  separate Receipt model — a receipt *is* a verified Payment carrying
  `receipt_ref`). A small `ReceiptSerializer` was added in `tenants/me_serializers.py`
  since the rent app only serialized `RentRequest`, not `Payment`.
- `/me/rent` returns a `{schedule, requests}` payload (two reused serializers) so
  the tenant gets both the planned schedule and the asks in one call.
- All three endpoints are plain `APIView`s gated by `IsLinkedTenant` with reads
  routed through the T-001 `tenant_account` scoping helpers (not a viewset),
  keeping the read-only tenant surface one explicit, auditable place.
### Files touched (actual)
- Add: `apps/api/khatir/tenants/me_views.py`
- Add: `apps/api/khatir/tenants/me_serializers.py`
- Add: `apps/api/khatir/tenants/tests/test_me_endpoints.py`
- Update: `apps/api/khatir/tenants/urls.py` (`/me/lease`, `/me/rent`, `/me/receipts`)
## 15. Notes
GET /api/v1/me/lease (current lease), /me/rent (schedule + requests), /me/receipts (their receipts). All scoped via tenant_for_user. Read-only. Tests for scoping.
