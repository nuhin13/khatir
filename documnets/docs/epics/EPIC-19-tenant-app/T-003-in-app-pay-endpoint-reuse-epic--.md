---
id: T-003
epic: EPIC-19
title: In-app pay endpoint (reuse EPIC-07 proof)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-07.T-006]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · In-app pay endpoint (reuse EPIC-07 proof)

## 1. Feature goal
POST /api/v1/me/rent/{id}/pay — submit payment proof in-app, feeding the SAME PaymentProof pipeline as the web-link (EPIC-07 T-006). Tenant-scoped. No new proof logic — reuse.

## 2. Business logic
POST /api/v1/me/rent/{id}/pay — submit payment proof in-app, feeding the SAME PaymentProof pipeline as the web-link (EPIC-07 T-006). Tenant-scoped. No new proof logic — reuse.

## 3. What this task DOES
See feature goal. Reuses existing pipelines (EPIC-07/08) — does NOT duplicate logic.

## 5. Files & changes
### Add/Update
- tenants/me_views.py or per-domain /me endpoints; tests.

## 6–10.
DB: reads/writes via existing models. Tenant-scoped. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core endpoint per goal — `POST /api/v1/me/rent/{id}/pay`
- [x] tenant_for_user scoping (own only) — `leases_for_tenant_user` filter, foreign id → 404
- [x] reuse existing pipeline (no duplication) — extracted `submit_payment_proof`; web view now calls it too
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
- The proof-submit core (create `PaymentProof` + advance `sent → proof_submitted`)
  previously lived only inside `rent/web_views.submit_proof`. To honour §3 (reuse,
  no duplication), it was extracted into `rent.services.submit_payment_proof`; the
  web view now calls that same function, so the web link and the in-app endpoint
  share one pipeline.
- The screenshot field uses DRF `FileField` (not `ImageField`) — Pillow is not a
  project dependency, and the web flow likewise stores raw bytes without image
  validation. Same 8 MiB cap as the web page.
- Endpoint returns `201` with the updated `RentRequestSerializer` body (the
  request now in `proof_submitted`), so the app can refresh its rent view in one
  round-trip. A re-submit against an already verified/rejected request creates the
  proof but never regresses status (covered by the shared service + a test).
### Files touched (actual)
- Update: `apps/api/khatir/rent/services.py` (new `submit_payment_proof`)
- Update: `apps/api/khatir/rent/web_views.py` (reuse the service; drop inlined create)
- Update: `apps/api/khatir/tenants/me_serializers.py` (`InAppProofSerializer`)
- Update: `apps/api/khatir/tenants/me_views.py` (`MeRentPayView`)
- Update: `apps/api/khatir/tenants/urls.py` (`me/rent/<int:pk>/pay`)
- Add: `apps/api/khatir/tenants/tests/test_me_pay_endpoint.py`
## 15. Notes
POST /api/v1/me/rent/{id}/pay — submit payment proof in-app, feeding the SAME PaymentProof pipeline as the web-link (EPIC-07 T-006). Tenant-scoped. No new proof logic — reuse.
