---
id: T-003
epic: EPIC-00
title: Docker-compose local stack (Postgres, Redis)
layer: infra
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-001, T-002]
blocks: [T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Docker-compose local stack (Postgres, Redis)

## 1. Feature goal
Provide a one-command local development stack: PostgreSQL and Redis (and slots for API + admin) via docker-compose, so the whole team/agents develop against identical infra.

## 2. Business logic
Use latest stable PostgreSQL (17.x) and Redis (8.x) images. Data persists across restarts via named volumes. Reads connection settings from `.env`.

## 3. What this task DOES
- Create `docker-compose.yml` at repo root with services: `db` (postgres:17), `redis` (redis:8).
- Add service stubs (commented or build-context-ready) for `api` and `admin` to be enabled by T-004/T-009.
- Named volumes for Postgres data.
- Healthchecks for db and redis.
- Wire env from `.env`.
- Create `infra/docker/` Dockerfiles placeholders for api and admin (filled by T-004/T-009).

## 4. What this task does NOT do
- Does not build the Django or admin images (those tasks add their Dockerfiles + enable the compose services).

## 5. Files & changes
### Add
- `docker-compose.yml`
- `infra/docker/api.Dockerfile` (placeholder, completed in T-004)
- `infra/docker/admin.Dockerfile` (placeholder, completed in T-009)
### Update
- none
### Delete
- none (remove the relevant `.gitkeep` if adding real files in infra/docker)

## 6. Database changes
No schema. Provisions the Postgres instance.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
None (local containers).

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] `docker-compose.yml` with db (postgres:17) + redis (redis:8)
- [ ] Named volume for postgres data
- [ ] Healthchecks on db + redis
- [ ] Env wired from `.env` (DB_*, REDIS_URL)
- [ ] api + admin service stubs present (ready to enable)
- [ ] `docker compose up db redis` works and persists data across restarts

## 12. Test plan
### Manual QA
1. `docker compose up -d db redis` → both healthy.
2. `psql` connects with `.env` creds.
3. `redis-cli ping` → PONG.
4. Restart → data persists.

## 13. Acceptance criteria
- [ ] `docker compose up db redis` brings both up healthy.
- [ ] Connection settings come from `.env`.

## 14. Self-review
- [ ] Latest stable images used
- [ ] Volumes persist
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use Compose v2 syntax (no `version:` key needed).
- Default ports: Postgres 5432, Redis 6379 — but read host/port from `.env` so they can be overridden.
