---
id: T-004
epic: EPIC-21
title: Seed review config
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Seed review config

## 1. Feature goal
Seed `review_rating_scale` (int, 5) + `review_disclaimer_text` (bn/en, "private, not public").

## 3. What this task DOES
- Seed keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] seed review_rating_scale + review_disclaimer_text
- [x] idempotent + reversible
- [x] test

## 12. Test plan
### Automated
- test_review_config_seeded
## 13. Acceptance criteria
- [x] Config seeded; test passes.
## 14. Self-review
- [x] Disclaimer emphasizes private/not-public
### Deviations from spec
- Disclaimer stored as JSON `{"bn","en"}` in a `text` SystemConfig (mirrors the
  `area_options` bilingual-text pattern), since `SystemConfig` has one value
  column; `get_config("review_disclaimer_text")` returns the JSON string.
- Seeded as a `core` data migration (0013, chained off 0012) rather than the
  reviews app, since `SystemConfig` lives in core and all config seeds are core
  migrations.
### Files touched (actual)
- Add: `apps/api/khatir/core/migrations/0013_seed_review_config.py`
- Add: `apps/api/khatir/core/tests/test_seed_review_config.py`
## 15. Notes
- Disclaimer must state reviews are private between the parties and never published.
