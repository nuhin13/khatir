---
id: T-003
epic: EPIC-14
title: Provider abstraction + primary/fallback routing
layer: infra
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-004, T-005, T-006]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
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
- [x] ProviderRouter (fetch config, primary→fallback) — 60s TTL config cache
- [x] failure handling (try fallback, log failover_from)
- [x] usage logging hook (per call, success + failure)
- [x] Tests: primary success, primary fail→fallback, both fail (+ no-provider, inactive-skip, cache)
- [x] ruff + mypy clean (11 tests pass)

## 12. Test plan
### Automated
- test_primary_success, test_primary_fail_fallback, test_both_fail_raises
## 13. Acceptance criteria
- [x] Routing + fallback + logging; tests + lint pass.
## 14. Self-review
- [x] Failover logged; usage always recorded (one UsageRecord per attempt, success or fail)
### Deviations from spec
- Added `providers/__init__.py` re-exports and a generic `HTTPProvider` in
  `providers/base.py` (vendor clients subclass it in later tasks).
- Provider config is fetched via an injected `ConfigSource` callable and cached
  60s (env-overridable TTL per §15); the router stays provider-agnostic via the
  `Provider` protocol + `ProviderConfig`/`ProviderResult` dataclasses.
- Usage sink is a pluggable `UsageLogger` protocol (`NoOpUsageLogger` default);
  logging failures are swallowed so they never mask provider results.
- Tests use `pytest-asyncio` (added to dev deps; `asyncio_mode = auto`).
### Files touched (actual)
- services/ai-gateway/router.py (new)
- services/ai-gateway/providers/__init__.py, providers/base.py (new)
- services/ai-gateway/tests/test_router.py (new)
- services/ai-gateway/pyproject.toml, uv.lock (pytest-asyncio, isort, asyncio_mode)
## 15. Notes
- Config refresh: gateway caches provider config for 60s (TTL from env).
