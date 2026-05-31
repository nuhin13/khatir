# EPIC-14 · Admin — AI Providers + AI Gateway Service

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-11
**Tasks:** 12 · **External services:** Multiple AI vendors (OpenAI/Anthropic/Google/Verbex/Azure/Whisper)

---

## Business goal
Stand up the **AI gateway** FastAPI microservice and the admin UI to configure providers (chat/voice/ocr/lease) with primary+fallback, encrypted API keys, test-connection, and usage tracking — so the concrete AI vendor can be swapped with no code change, costs are controlled, and EPIC-04's OCR is retro-fitted through it.

## Scope
**In:** `services/ai-gateway` FastAPI microservice with provider abstraction, primary→fallback routing, usage logging. Admin UI: 4 category tabs (chat/voice/ocr/lease), provider select, model, encrypted API key, endpoint, test-connection, usage panel. Retrofit EPIC-04's OCR to call the gateway. NID-OCR DPA constraint (can't use a non-BD provider without a DPA reference).
**Out:** The AI features themselves (lease gen=EPIC-18, chatbot=EPIC-23, voice is already wired via EPIC-04).

## Dependencies
EPIC-11 (admin shell). EPIC-04 (OCR endpoint re-routes through gateway).

## Data-model changes
- `AIProvider`: category, provider_key, is_primary, is_fallback, model_name, api_key_enc, endpoint_url, params_json, dpa_reference, active.
- `AIUsageLog`: provider_id, category, request_count, tokens_used, cost_usd, success, latency_ms, failover_from, created_at.

## API surface
- Gateway service: `POST /gateway/extract-nid` (OCR), `POST /gateway/extract-voice`, `POST /gateway/chat`, `POST /gateway/generate-lease`.
- Admin: `GET/POST/PATCH /admin/api/ai-providers`, `POST /{id}/test-connection`, `GET /admin/api/ai-usage`.

## Acceptance criteria
- [ ] AI gateway service starts + routes OCR requests to configured primary provider with fallback.
- [ ] EPIC-04 OCR re-routed through gateway (no change to endpoint contract).
- [ ] Admin UI configures providers per category; test-connection works.
- [ ] NID DPA constraint enforced at save (non-BD provider requires dpa_reference).
- [ ] Usage logged per call.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | AIProvider + AIUsageLog models | backend | M | EPIC-00.T-005 |
| T-002 | AI gateway FastAPI service scaffold | infra | M | EPIC-00.T-001 |
| T-003 | Provider abstraction + primary/fallback routing | infra | M | T-002 |
| T-004 | OCR provider impl (in gateway) | infra | M | T-003 |
| T-005 | ASR + chat provider stubs (in gateway) | infra | S | T-003 |
| T-006 | Usage logging (per call) | infra | S | T-003 |
| T-007 | Django aiproxy client (calls gateway) | backend | S | T-002 |
| T-008 | Retrofit EPIC-04 OCR through gateway | backend | S | T-007, EPIC-04.T-005 |
| T-009 | Admin AI providers endpoints | backend | M | T-001, EPIC-11.T-002 |
| T-010 | Seed AI provider config keys | backend | XS | EPIC-00.T-005 |
| T-011 | Admin AI providers page (Next.js) | admin | M | T-009, EPIC-11.T-008 |
| T-012 | AI usage panel page (Next.js) | admin | M | T-009 |
