---
id: T-005
epic: EPIC-26
title: Seed gov-export config + flag
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-13.T-001]
blocks: []
external_services: []
feature_flags: [gov_export_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Seed gov-export config + flag

## 1. Feature goal
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.

## 2. Business logic
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
DB as described; backend. Consent + audit on export. Flag: [gov_export_enabled] (default OFF).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Consent respected + audit (where applicable) — N/A: seed-only task; consent + audit are enforced by the builder/endpoints (T-002/T-004)
- [x] Tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [x] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
- None. `gov_export_enabled` flag seeded in govexport app (chains off `featureflags.0002_seed_flags`); `gov_export_format_version` config seeded in core (chains off `core.0012_seed_compliance_config`) per orchestrator instruction that core seeds chain off the latest core migration.
### Files touched (actual)
- apps/api/khatir/govexport/migrations/0002_seed_gov_export_flag.py (gov_export_enabled flag, default OFF)
- apps/api/khatir/core/migrations/0013_seed_gov_export_config.py (gov_export_format_version = "2026.1")
- apps/api/khatir/govexport/tests/test_seed_gov_export_flag.py
- apps/api/khatir/core/tests/test_seed_gov_export_config.py
## 15. Notes
Seed gov_export_enabled flag (DEFAULT OFF) + gov_export_format_version config.
