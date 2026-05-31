---
id: T-002
epic: EPIC-24
title: Tenant-initiated share endpoints (consent + expiry)
layer: backend
size: M
status: todo
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
- [ ] Core implementation per goal
- [ ] Tenant-controlled + consent + factual-only as applicable
- [ ] Tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tenant-controlled + consent-gated + factual-only; tests pass.
## 14. Self-review
- [ ] Tenant initiates; consent logged; factual only; revocable
### Deviations from spec
### Files touched (actual)
## 15. Notes
POST /api/v1/me/history-shares — TENANT creates a share to a specific landlord, recording a ConsentRecord + expiry. Kill-switch gated. Only the tenant can create. Audited. NO landlord-initiated variant exists.
