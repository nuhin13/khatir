---
id: T-004
epic: EPIC-21
title: Seed review config
layer: backend
size: XS
status: todo
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
- [ ] seed review_rating_scale + review_disclaimer_text
- [ ] idempotent + reversible
- [ ] test

## 12. Test plan
### Automated
- test_review_config_seeded
## 13. Acceptance criteria
- [ ] Config seeded; test passes.
## 14. Self-review
- [ ] Disclaimer emphasizes private/not-public
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Disclaimer must state reviews are private between the parties and never published.
