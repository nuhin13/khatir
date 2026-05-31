---
id: T-010
epic: EPIC-24
title: No landlord-initiated lookup architecture test
layer: cross-cutting
size: M
status: todo
preferred_agent: codex
depends_on: [T-002, T-003]
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

# T-010 · No landlord-initiated lookup architecture test

## 1. Feature goal
CRITICAL legal test: assert NO endpoint lets a landlord look up a tenant's history without that tenant having initiated + consented to a share. Enumerate routes; prove no landlord-query path exists. Hard compliance gate.

## 2. Business logic
CRITICAL legal test: assert NO endpoint lets a landlord look up a tenant's history without that tenant having initiated + consented to a share. Enumerate routes; prove no landlord-query path exists. Hard compliance gate.

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
- [ ] Prove NO landlord-initiated lookup path
- [ ] Tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; tenant-controlled + consent-gated + factual-only; tests pass.
## 14. Self-review
- [ ] No landlord-query path exists anywhere
### Deviations from spec
### Files touched (actual)
## 15. Notes
CRITICAL legal test: assert NO endpoint lets a landlord look up a tenant's history without that tenant having initiated + consented to a share. Enumerate routes; prove no landlord-query path exists. Hard compliance gate.
