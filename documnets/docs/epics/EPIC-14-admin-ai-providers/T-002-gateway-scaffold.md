---
id: T-002
epic: EPIC-14
title: AI gateway FastAPI service scaffold
layer: infra
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-001]
blocks: [T-003, T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] FastAPI service at services/ai-gateway
- [ ] Dockerfile (latest stable FastAPI stack)
- [ ] compose ai-gateway service
- [ ] /healthz endpoint
- [ ] config from env (GATEWAY_SECRET for auth from Django)
- [ ] ruff + mypy clean

## 12. Test plan
### Manual QA
1. docker compose up ai-gateway → /healthz → 200.
## 13. Acceptance criteria
- [ ] Gateway service runs; /healthz green; compose entry.
## 14. Self-review
- [ ] Latest stable FastAPI; no secrets hardcoded
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Gateway is a thin router — no business logic, no DB. Reads provider config from a call to Django's /admin/api/ai-providers or from a Redis-cached config.
