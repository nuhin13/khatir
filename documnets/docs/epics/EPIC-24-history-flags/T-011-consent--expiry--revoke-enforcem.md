---
id: T-011
epic: EPIC-24
title: Consent + expiry + revoke enforcement test
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-002, T-004]
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

# T-011 · Consent + expiry + revoke enforcement test

## 1. Feature goal
Test: recipient view works only while active; expired/revoked → 403; every share has a ConsentRecord; revoke is instant.

## 2. Business logic
Test: recipient view works only while active; expired/revoked → 403; every share has a ConsentRecord; revoke is instant.

## 3. What this task DOES
See feature goal. Built defensively — tenant-controlled, consent-per-share, factual-only, kill-switchable.

## 5. Files & changes
### Add/Update
- khatir/historyshare/... or features/historyshare/... ; tests.

## 6–10.
DB/web as described; backend. No external. Flag: [].

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
Test: recipient view works only while active; expired/revoked → 403; every share has a ConsentRecord; revoke is instant.
