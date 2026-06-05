---
id: T-003
epic: EPIC-24
title: Recipient view endpoint (token, active-only)
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [T-001]
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

# T-003 · Recipient view endpoint (token, active-only)

## 1. Feature goal
GET /api/v1/history-shares/{token} — the recipient landlord views the factual stats ONLY while the share is active (not expired/revoked) and consent valid. Read-only, no export. Token-scoped.

## 2. Business logic
GET /api/v1/history-shares/{token} — the recipient landlord views the factual stats ONLY while the share is active (not expired/revoked) and consent valid. Read-only, no export. Token-scoped.

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
- A share is addressed by an opaque, unguessable `token` (`secrets.token_urlsafe`),
  not its pk — added `HistoryShare.token` (unique, editable=False) + migration 0002.
  The token IS the capability: `GET /api/v1/history-shares/{token}` is `AllowAny`
  (a landlord can only follow a tenant-issued link, never enumerate/look up).
- Read gate = `is_active()` AND new `is_consent_valid()` (consent not withdrawn/expired),
  combined in `HistoryShare.is_readable()`. Revoked/expired/consent-invalid/unknown
  all return 404 so lifecycle state never leaks.
- Recipient serializer (`HistoryShareRecipientSerializer`) exposes factual snapshot +
  scope + expiry ONLY — no internal id, no consent_record id, no recipient id, no
  subjective field. Read-only by construction (GET only; POST/PUT/PATCH/DELETE → 405).
### Files touched (actual)
- apps/api/khatir/historyshare/models.py (token field, generate_share_token, is_consent_valid, is_readable)
- apps/api/khatir/historyshare/migrations/0002_historyshare_token.py
- apps/api/khatir/historyshare/serializers.py (HistoryShareRecipientSerializer; add token to HistoryShareSerializer)
- apps/api/khatir/historyshare/views.py (HistoryShareRecipientView)
- apps/api/khatir/historyshare/urls.py (history-shares/<token> route)
- apps/api/khatir/historyshare/tests/test_recipient_api.py
## 15. Notes
GET /api/v1/history-shares/{token} — the recipient landlord views the factual stats ONLY while the share is active (not expired/revoked) and consent valid. Read-only, no export. Token-scoped.
