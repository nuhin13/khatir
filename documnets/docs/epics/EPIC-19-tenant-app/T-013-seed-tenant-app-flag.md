---
id: T-013
epic: EPIC-19
title: Seed tenant app flag
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-13.T-001]
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

# T-013 · Seed tenant app flag

## 1. Feature goal
Seed tenant_app_enabled feature flag (default on).

## 2. Business logic
Seed tenant_app_enabled feature flag (default on).

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
Test / seed only. No external. Seeds tenant_app_enabled flag.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests pass.
## 14. Self-review
- [x] Follows conventions
### Deviations from spec
- None. Migration lives in the featureflags app (Domain 8 owner of FeatureFlag), chained off its latest migration 0002_seed_flags, mirroring the established flag-seed pattern.
### Files touched (actual)
- apps/api/khatir/featureflags/migrations/0003_seed_tenant_app_flag.py
- apps/api/khatir/featureflags/tests/test_seed_tenant_app_flag.py
## 15. Notes
Seed tenant_app_enabled feature flag (default on).
