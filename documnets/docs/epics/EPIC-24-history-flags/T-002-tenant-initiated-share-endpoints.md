---
id: T-002
epic: EPIC-24
title: Tenant-initiated share endpoints (consent + expiry)
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [T-001, EPIC-13.T-002]
blocks: []
external_services: []
feature_flags: [history_flags_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Tenant-initiated share endpoints (consent + expiry)

## 1. Feature goal
POST /api/v1/me/history-shares — TENANT creates a share to a specific landlord, recording a ConsentRecord + expiry. Kill-switch gated. Only the tenant can create. Audited. NO landlord-initiated variant exists.

## 2. Business logic
POST /api/v1/me/history-shares — TENANT creates a share to a specific landlord, recording a ConsentRecord + expiry. Kill-switch gated. Only the tenant can create. Audited. NO landlord-initiated variant exists.

## 3. What this task DOES
See feature goal. Built defensively — tenant-controlled, consent-per-share, factual-only, kill-switchable.

## 5. Files & changes
### Add/Update
- khatir/historyshare/... or features/historyshare/... ; tests.

## 6–10.
DB/web as described; backend. No external. Flag: [history_flags_feature].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Tenant-controlled + consent + factual-only as applicable
- [x] Tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tenant-controlled + consent-gated + factual-only; tests pass.
## 14. Self-review
- [x] Tenant initiates; consent logged; factual only; revocable
### Deviations from spec
- Route mounted at `POST /api/v1/me/history-shares` (new `khatir.historyshare.urls`,
  included in `config/urls.py`). Acting tenant is resolved from `request.user`
  (`Tenant.linked_user`) in the service, never from the body. Recipient must be a
  landlord-role user (serializer queryset). Kill-switch gated on
  `history_flags_feature` (default ON, matching the seeded state) at the view AND
  re-checked in the service. Per-share `ConsentRecord` (`pdpa_data_sharing`) is
  created with `granted_at=now` and `expires_at` mirroring the share; the whole
  create is atomic so a rejected expiry leaves no orphan consent. Factual stats
  snapshotted via `compute_factual_stats` (T-001). Customer-facing `audit()`
  writes a `history_share.create` entry. No model/migration changes (only runtime
  rows), so `makemigrations --check` is clean.
### Files touched (actual)
- apps/api/khatir/historyshare/{flags,services,serializers,views,urls}.py
- apps/api/khatir/historyshare/tests/test_share_api.py
- apps/api/config/urls.py (register historyshare routes)
## 15. Notes
POST /api/v1/me/history-shares — TENANT creates a share to a specific landlord, recording a ConsentRecord + expiry. Kill-switch gated. Only the tenant can create. Audited. NO landlord-initiated variant exists.
