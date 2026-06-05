---
id: T-005
epic: EPIC-24
title: Seed history-flags config
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
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

# T-005 · Seed history-flags config

## 1. Feature goal
Seed history_share_default_expiry_days (int, e.g. 30) + history_share_disclaimer_text.

## 2. Business logic
Seed history_share_default_expiry_days (int, e.g. 30) + history_share_disclaimer_text.

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
None. Config seeded in core's own migration chain (0013) per the established
seed-migration pattern (0002–0012), since SystemConfig lives in the core app.
### Files touched (actual)
- apps/api/khatir/core/migrations/0013_seed_history_flags_config.py
- apps/api/khatir/core/tests/test_seed_history_flags_config.py
## 15. Notes
Seed history_share_default_expiry_days (int, e.g. 30) + history_share_disclaimer_text.
