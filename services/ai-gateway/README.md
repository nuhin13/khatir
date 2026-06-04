# AI Gateway (`services/ai-gateway`)

Thin FastAPI router that all Khatir AI provider calls flow through (EPIC-14).
**No database, no business logic** — it routes requests to upstream AI providers
using configuration the Django backend supplies. This scaffold (T-002) ships the
service skeleton and the `/healthz` liveness probe; provider routing endpoints
are added by later tasks (T-003, T-007).

## Run locally

```bash
uv sync
uv run uvicorn main:app --reload --port 8100
curl http://localhost:8100/healthz   # {"status":"ok","service":"khatir-ai-gateway"}
```

Or via the compose stack from the repo root:

```bash
docker compose up ai-gateway
```

## Test & lint

```bash
uv run ruff check .
uv run pytest -q
uv run mypy .
```

## Configuration

Reads env from the shared repo `.env` (see `.env.example` → "AI Gateway" block):

| Var | Purpose | Default |
|-----|---------|---------|
| `AI_GATEWAY_URL` | Where Django reaches the gateway | `http://localhost:8100` |
| `AI_GATEWAY_INTERNAL_TOKEN` | Shared secret Django presents on each call; blank disables auth in local dev | `""` |
