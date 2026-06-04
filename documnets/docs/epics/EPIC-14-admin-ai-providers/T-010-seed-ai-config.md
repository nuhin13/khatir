---
id: T-010
epic: EPIC-14
title: Seed AI provider config keys
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Seed AI provider config keys

## 1. Feature goal
Seed `ai_gateway_url` and `ai_gateway_secret` SystemConfig keys + the gateway cache TTL.

## 3. What this task DOES
- Seed 3 keys; test.

## 5. Files & changes
### Add
- seed migration/command; test

## 6. Database changes
SystemConfig rows.
## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] seed ai_gateway_url, ai_gateway_secret, ai_provider_cache_ttl_seconds
- [x] idempotent + reversible
- [x] test

## 12. Test plan
### Automated
- test_ai_config_seeded
## 13. Acceptance criteria
- [x] Keys seeded; test passes.
## 14. Self-review
- [x] ai_gateway_secret treated as sensitive (not logged)
### Deviations from spec
### Files touched (actual)
## 15. Notes
- ai_gateway_secret is a shared secret between Django and the gateway — keep it out of logs.
