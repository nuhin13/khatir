---
id: T-003
epic: EPIC-14
title: Provider abstraction + primary/fallback routing
layer: infra
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-004, T-005, T-006]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Provider abstraction + primary/fallback routing

## 1. Feature goal
A provider-agnostic router in the gateway: for a given category (ocr/voice/chat/lease), call the primary provider; if it fails, call the fallback; log usage.

## 2. Business logic
Abstract ProviderRouter(category) → fetches active providers from config → tries primary → on failure tries fallback → logs usage (success/fail, latency, failover_from). Providers are thin HTTP clients per vendor API.

## 3. What this task DOES
- ProviderRouter class; primary→fallback; usage logging hook; tests (mock providers).

## 5. Files & changes
### Add
- services/ai-gateway/router.py, providers/base.py; tests/test_router.py

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] ProviderRouter (fetch config, primary→fallback)
- [ ] failure handling (try fallback, log failover_from)
- [ ] usage logging hook (per call)
- [ ] Tests: primary success, primary fail→fallback, both fail
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_primary_success, test_primary_fail_fallback, test_both_fail_raises
## 13. Acceptance criteria
- [ ] Routing + fallback + logging; tests + lint pass.
## 14. Self-review
- [ ] Failover logged; usage always recorded
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Config refresh: gateway caches provider config for 60s (TTL from env).
