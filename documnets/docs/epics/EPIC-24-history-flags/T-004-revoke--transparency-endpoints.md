---
id: T-004
epic: EPIC-24
title: Revoke + transparency endpoints
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-001]
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

# T-004 · Revoke + transparency endpoints

## 1. Feature goal
GET /api/v1/me/history-shares (tenant sees all their shares: what/who/when/status). POST /{id}/revoke (tenant revokes instantly). Full tenant transparency + control.

## 2. Business logic
GET /api/v1/me/history-shares (tenant sees all their shares: what/who/when/status). POST /{id}/revoke (tenant revokes instantly). Full tenant transparency + control.

## 3. What this task DOES
See feature goal. Built defensively — tenant-controlled, consent-per-share, factual-only, kill-switchable.

## 5. Files & changes
### Add/Update
- khatir/historyshare/... or features/historyshare/... ; tests.

## 6–10.
DB/web as described; backend. No external. Flag: [].

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
- Transparency list mounted as `GET /api/v1/me/history-shares` on the existing
  `HistoryShareCreateView` (now GET+POST; route renamed `history-share-list-create`).
  Revoke mounted as `POST /api/v1/me/history-shares/{id}/revoke`
  (`HistoryShareRevokeView`). Both `IsTenant`-gated; the acting tenant is resolved
  from `request.user` (never the body), so the list/revoke are strictly scoped to
  the caller's own shares.
- `GET` returns ALL the tenant's shares (active/expired/revoked) via a new
  `HistoryShareOwnerSerializer` exposing what (scope, factual_stats) / who
  (recipient_landlord) / when (created_at, expires_at, revoked_at) / `status`
  (new `HistoryShare.status()` → active|expired|revoked). Factual-only — no
  subjective field. The list is NOT kill-switch gated (a tenant can always
  inspect what they shared).
- `revoke_history_share` (services.py, `@transaction.atomic`) sets `revoked_at=now`
  AND withdraws the linked per-share `ConsentRecord` (`revoked_at`), so the
  recipient read path closes via both gates; audited (`history_share.revoke`).
  Idempotent (re-revoke is a no-op preserving the original time). A share that
  is not the caller's is 404 (never 403) so another tenant's existence never
  leaks. Revoke is deliberately NOT kill-switch gated — withdrawing consent must
  always be possible. No model/migration changes (runtime fields only) →
  makemigrations --check clean.
### Files touched (actual)
- apps/api/khatir/historyshare/models.py (status() helper)
- apps/api/khatir/historyshare/services.py (list_history_shares, revoke_history_share)
- apps/api/khatir/historyshare/serializers.py (HistoryShareOwnerSerializer)
- apps/api/khatir/historyshare/views.py (GET on create view; HistoryShareRevokeView)
- apps/api/khatir/historyshare/urls.py (list+revoke routes)
- apps/api/khatir/historyshare/tests/test_transparency_api.py
## 15. Notes
GET /api/v1/me/history-shares (tenant sees all their shares: what/who/when/status). POST /{id}/revoke (tenant revokes instantly). Full tenant transparency + control.
