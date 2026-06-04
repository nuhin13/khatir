---
id: T-006
epic: EPIC-14
title: Usage logging (per call)
layer: infra
size: S
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Usage logging (per call)

## 1. Feature goal
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.

## 2. Business logic
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.

## 3. What this task DOES
See feature goal. Implements the above in the correct layer (infra=gateway, backend=Django).

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No new DB tables (beyond T-001). External: AI vendor APIs (mocked in tests). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation — `usage.py` HTTPUsageLogger + build_usage_logger factory
- [x] Tests (mocked external) — httpx.MockTransport; 6 new tests
- [x] ruff + mypy clean (gateway): ruff All checks passed, mypy Success; 24 tests pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass. After each call the router's
  usage hook POSTs a UsageRecord (provider/category/tokens/cost/latency/success/
  failover_from) to Django's `/admin/api/ai-usage`.
## 14. Self-review
- [x] API keys from config; not logged — internal token sent only as the
  Authorization header, never in a record/log; only accounting metadata travels
  this path (no api_key field on UsageRecord).
### Deviations from spec
- Implemented the HTTP POST sink (chose POST-to-Django over the Redis-queue
  alternative the goal offers as "or"). The router (T-003) already exposes the
  `UsageLogger` protocol + `UsageRecord`; T-006 adds the concrete
  `HTTPUsageLogger` and a `build_usage_logger` factory that degrades to
  `NoOpUsageLogger` when no `django_base_url` is configured (local dev/tests).
- Added `django_base_url`, `ai_usage_path`, `ai_usage_timeout_seconds` settings.
### Files touched (actual)
- services/ai-gateway/usage.py (new)
- services/ai-gateway/tests/test_usage.py (new)
- services/ai-gateway/config.py (usage-logging settings)
- services/ai-gateway/pyproject.toml (isort known-first-party += "usage")
## 15. Notes
After each gateway call, POST usage to Django /admin/api/ai-usage endpoint (or write to a shared Redis queue). Records tokens/cost/latency/success/failover.
