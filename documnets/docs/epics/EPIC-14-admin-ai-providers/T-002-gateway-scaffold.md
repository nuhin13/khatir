---
id: T-002
epic: EPIC-14
title: AI gateway FastAPI service scaffold
layer: infra
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-001]
blocks: [T-003, T-007]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · AI gateway FastAPI service scaffold

## 1. Feature goal
Stand up the `services/ai-gateway` FastAPI microservice with health check, project structure, and Docker/compose entry — the container all AI calls route through.

## 2. Business logic
FastAPI (latest stable) + pydantic + httpx + uvicorn. Config from env (provider credentials forwarded). Reads AIProvider config from Django DB via HTTP call or a shared config store. Health: GET /healthz.

## 3. What this task DOES
- FastAPI service at services/ai-gateway/; Dockerfile; compose service; health endpoint; structure per 02_project_structure.md.

## 5. Files & changes
### Add
- services/ai-gateway/{main.py, config.py, Dockerfile, requirements.txt}
### Update
- docker-compose.yml (ai-gateway service)

## 6–10.
No DB in gateway (reads config from Django/env); no feature flags.

## 7. API changes
| GET | /healthz | none | 200 |

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] FastAPI service at services/ai-gateway (uv project) — f93ed5d base
- [x] Dockerfile (latest stable FastAPI stack; uv-managed, non-root, :8100)
- [x] compose ai-gateway service (port 8100, /healthz healthcheck)
- [x] /healthz endpoint (200 + {status, service})
- [x] config from env (AI_GATEWAY_INTERNAL_TOKEN for auth from Django)
- [x] ruff + mypy clean (mypy: no issues in 4 source files)

## 12. Test plan
### Manual QA
1. docker compose up ai-gateway → /healthz → 200.
## 13. Acceptance criteria
- [x] Gateway service runs; /healthz green; compose entry.
## 14. Self-review
- [x] Latest stable FastAPI (0.136.x); no secrets hardcoded (token from env)
### Deviations from spec
- Used **uv** (pyproject.toml + uv.lock) as the primary dependency manager per
  the infra contract; `requirements.txt` is generated via `uv export` and kept
  for parity with the task's listed files.
- Auth secret env var is `AI_GATEWAY_INTERNAL_TOKEN` (already defined in
  `.env.example`) rather than the placeholder `GATEWAY_SECRET` named in §11.
- Service listens on port **8100** to match `AI_GATEWAY_URL` in `.env.example`.
### Files touched (actual)
- services/ai-gateway/{pyproject.toml, uv.lock, main.py, config.py, Dockerfile,
  .dockerignore, requirements.txt, README.md, tests/__init__.py, tests/test_health.py}
- docker-compose.yml (added ai-gateway service, additive)
## 15. Notes
- Gateway is a thin router — no business logic, no DB. Reads provider config from a call to Django's /admin/api/ai-providers or from a Redis-cached config.
