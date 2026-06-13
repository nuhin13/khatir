---
id: T-001
epic: EPIC-24
title: HistoryShare model + factual-stats computation
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [EPIC-07.T-001, EPIC-16.T-001]
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

# T-001 · HistoryShare model + factual-stats computation

## 1. Feature goal
HistoryShare(tenant FK, recipient_landlord FK, scope json, consent_record FK, expires_at, revoked_at, created_at). A pure function computes FACTUAL stats only (on_time_payment_count, total_payments, lease_completed bool) from EPIC-07 data at share time. NO subjective field. Migration + tests.

## 2. Business logic
HistoryShare(tenant FK, recipient_landlord FK, scope json, consent_record FK, expires_at, revoked_at, created_at). A pure function computes FACTUAL stats only (on_time_payment_count, total_payments, lease_completed bool) from EPIC-07 data at share time. NO subjective field. Migration + tests.

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
- Stats live in `historyshare/stats.py` (pure fn) and are snapshotted onto the share's `factual_stats` JSON at share time; `scope` and `factual_stats` are JSONFields. No subjective field exists (enforced by a test).
### Files touched (actual)
- apps/api/khatir/historyshare/{__init__,apps,models,stats,admin}.py
- apps/api/khatir/historyshare/migrations/0001_initial.py
- apps/api/khatir/historyshare/tests/{__init__,factories,test_models,test_stats}.py
- apps/api/config/settings/base.py (register app)
## 15. Notes
HistoryShare(tenant FK, recipient_landlord FK, scope json, consent_record FK, expires_at, revoked_at, created_at). A pure function computes FACTUAL stats only (on_time_payment_count, total_payments, lease_completed bool) from EPIC-07 data at share time. NO subjective field. Migration + tests.
