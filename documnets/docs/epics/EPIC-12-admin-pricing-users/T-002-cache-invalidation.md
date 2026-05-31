---
id: T-002
epic: EPIC-12
title: Cache invalidation on tier change (<60s)
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001]
blocks: [T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Cache invalidation on tier change (<60s)

## 1. Feature goal
Ensure /config/public reflects any tier change within 60 seconds for all clients.

## 2. Business logic
On PricingTier save (post-save signal or explicit call in T-001 service): bust the /config/public cache key. With a 60s max TTL this guarantees clients see the change within 60s.

## 3. What this task DOES
- Signal/hook that clears the cache key on tier write; test confirming the change is visible after bust.

## 5. Files & changes
### Add/Update
- admin_portal/signals.py or billing/signals.py; tests/test_cache_invalidation.py

## 6. Database changes
None.
## 7. API changes
None (affects /config/public indirectly).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] post-save signal on PricingTier busts /config/public cache key
- [ ] test: edit tier → config/public stale key gone
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_cache_busted_on_tier_change
### Manual QA
1. Edit tier → GET /config/public → reflects change immediately.

## 13. Acceptance criteria
- [ ] Cache busted on tier change; /config/public reflects within TTL; test passes.

## 14. Self-review
- [ ] Cache key consistent with EPIC-10 T-005
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use the same cache key that EPIC-10 T-005 sets. If using Django cache, `cache.delete(key)`.
