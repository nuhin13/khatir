---
id: T-004
epic: EPIC-00
title: Django API scaffold (settings, uv, ruff, healthz)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-005, T-006, T-011, T-013, T-014, T-015]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Django API scaffold (settings, uv, ruff, healthz)

## 1. Feature goal
Create the Django + DRF backend project at `apps/api/` that boots, connects to Postgres/Redis, exposes a health check, and has tooling (uv, ruff, mypy, pytest) wired — the base every backend epic builds on.

## 2. Business logic
Follow `01_stack_and_standards.md` (latest stable Django/DRF, uv, ruff) and `02_project_structure.md` (config/ layout). Settings split into base/dev/prod/test reading env via pydantic-settings or django-environ. No domain models yet.

## 3. What this task DOES
- `uv`-managed Django project under `apps/api/` with `pyproject.toml` (ruff + mypy + pytest config).
- `config/` package: `settings/{base,dev,prod,test}.py`, `urls.py`, `wsgi.py`, `asgi.py`.
- DRF installed + configured (default pagination, exception handler hook reserved for T-005).
- DB (psycopg3) + Redis cache configured from env.
- `GET /healthz` → `{status: ok}` (no auth), and `GET /api/v1/config/public` returning a valid empty envelope.
- API routes mounted under `/api/v1/`.
- `conftest.py` + a passing `test_healthz`.
- Complete `infra/docker/api.Dockerfile` and enable the `api` service in `docker-compose.yml`.

## 4. What this task does NOT do
- No auth, no domain models, no core base classes (T-005).
- No Celery (T-006).

## 5. Files & changes
### Add
- `apps/api/pyproject.toml`, `apps/api/uv.lock`, `apps/api/manage.py`, `apps/api/conftest.py`
- `apps/api/config/__init__.py`, `settings/{base,dev,prod,test}.py`, `urls.py`, `wsgi.py`, `asgi.py`
- `apps/api/khatir/__init__.py` (namespace package for apps)
- `apps/api/khatir/health/` minimal app OR a health view in config — healthz + config/public
- `apps/api/tests/test_healthz.py`
### Update
- `infra/docker/api.Dockerfile` (complete it)
- `docker-compose.yml` (enable `api` service, depends_on db+redis)
### Delete
- none

## 6. Database changes
Runs initial Django migrations (auth, contenttypes, sessions). No domain tables.

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | /healthz | none | — | {"status":"ok"} | 200 |
| GET | /api/v1/config/public | none | — | {"flags":{},"config":{}} | 200 |

## 8. UI changes
No UI changes.

## 9. External services
None. Connects to local Postgres + Redis from T-003.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] uv project + pyproject.toml (ruff line-length 100, mypy, pytest-django)
- [ ] Settings split base/dev/prod/test reading env
- [ ] DRF configured (pagination default, exception handler placeholder)
- [ ] psycopg3 + Redis cache from env
- [ ] /healthz + /api/v1/config/public
- [ ] /api/v1 mounting in urls.py
- [ ] conftest.py + test_healthz passes
- [ ] api.Dockerfile completed; compose `api` service enabled
- [ ] `make`-free run works: `uv run python manage.py runserver` boots
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_healthz → GET /healthz returns 200 {status: ok}
- test_config_public → GET /api/v1/config/public returns 200 valid envelope
### Manual QA
1. `docker compose up` → api reachable.
2. `curl localhost:8000/healthz` → ok.

## 13. Acceptance criteria
- [ ] Django boots against Dockerized Postgres + Redis.
- [ ] /healthz and /api/v1/config/public respond.
- [ ] pytest + ruff + mypy pass.

## 14. Self-review
- [ ] Latest stable Django/DRF used (note exact versions)
- [ ] Settings read from env, no hardcoded secrets
- [ ] Tests pass
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use the latest stable Django (6.x at time of writing) — verify on PyPI before pinning in uv.lock.
- `DJANGO_SETTINGS_MODULE` selected via `DJANGO_ENV` env (dev default).
- Keep the exception-handler slot wired so T-005 can drop in the standard error envelope.
- `config/public` returns empty `flags`/`config` now; later epics populate it.
