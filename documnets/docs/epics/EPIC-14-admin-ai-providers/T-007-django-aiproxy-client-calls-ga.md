---
id: T-007
epic: EPIC-14
title: Django aiproxy client (calls gateway)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-002]
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

# T-007 · Django aiproxy client (calls gateway)

## 1. Feature goal
A thin client in Django (khatir/ai_providers/client.py) that calls the gateway over HTTP with the GATEWAY_SECRET. Returns the normalized result. Tests (mocked gateway).

## 2. Business logic
A thin client in Django (khatir/ai_providers/client.py) that calls the gateway over HTTP with the GATEWAY_SECRET. Returns the normalized result. Tests (mocked gateway).

## 3. What this task DOES
See feature goal. Implements the above in the correct layer (infra=gateway, backend=Django).

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No new DB tables (beyond T-001). External: AI vendor APIs (mocked in tests). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation — khatir/ai_providers/client.py (call_gateway + AIGatewayResult/AIGatewayError)
- [x] Tests (mocked external) — 10 tests, requests.post patched
- [x] ruff clean (backend)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] API keys from config; not logged (internal token read from settings, set on Authorization header, never logged; payloads not logged)
### Deviations from spec
- Auth secret is `AI_GATEWAY_INTERNAL_TOKEN` (already in `.env.example` and used
  by the gateway, T-002) rather than the placeholder `GATEWAY_SECRET` in the goal.
- Uses `requests` (added as an explicit dep) at the Django edge; the gateway
  itself uses httpx. Client targets `{AI_GATEWAY_URL}/v1/{category}` — the
  per-category endpoint the gateway router (T-003) exposes.
### Files touched (actual)
- apps/api/khatir/ai_providers/client.py (new)
- apps/api/khatir/ai_providers/tests/test_client.py (new)
- apps/api/config/settings/base.py (AI_GATEWAY_* settings, additive)
- apps/api/pyproject.toml + uv.lock (requests dep)
## 15. Notes
A thin client in Django (khatir/ai_providers/client.py) that calls the gateway over HTTP with the GATEWAY_SECRET. Returns the normalized result. Tests (mocked gateway).
