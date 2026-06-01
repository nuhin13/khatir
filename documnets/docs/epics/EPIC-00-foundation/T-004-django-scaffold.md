---
id: T-004
epic: EPIC-00
title: Django API scaffold (settings, uv, ruff, healthz)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: [T-005, T-006, T-011, T-013, T-014, T-015]
external_services: []
feature_flags: []
started_at: 2026-06-02
completed_at: 2026-06-02
executed_by: claude-code
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
- [x] uv project + pyproject.toml (ruff line-length 100, mypy, pytest-django)
- [x] Settings split base/dev/prod/test reading env
- [x] DRF configured (pagination default, exception handler placeholder)
- [x] psycopg3 + Redis cache from env
- [x] /healthz + /api/v1/config/public
- [x] /api/v1 mounting in urls.py
- [x] conftest.py + test_healthz passes
- [x] api.Dockerfile completed; compose `api` service enabled
- [x] `make`-free run works: `uv run python manage.py runserver` boots
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_healthz → GET /healthz returns 200 {status: ok}
- test_config_public → GET /api/v1/config/public returns 200 valid envelope
### Manual QA
1. `docker compose up` → api reachable.
2. `curl localhost:8000/healthz` → ok.

## 13. Acceptance criteria
- [x] Django boots against Dockerized Postgres + Redis.
- [x] /healthz and /api/v1/config/public respond.
- [x] pytest + ruff + mypy pass.

## 14. Self-review
- [x] Latest stable Django/DRF used (note exact versions) — Django 6.0.5, DRF 3.17.1, psycopg 3.3.4, gunicorn 26.0.0, redis 8.0.0, django-environ 0.13.0. Python 3.14 (uv-resolved; lock requires-python >=3.13). Docker image built on python3.13.
- [x] Settings read from env, no hardcoded secrets — all config via django-environ in `config/settings/`; prod requires `DJANGO_SECRET_KEY`/`DJANGO_ALLOWED_HOSTS`. Local dev key is an obvious placeholder only.
- [x] Tests pass — `uv run pytest` → `2 passed`. ruff + mypy clean.

### Deviations from spec
- **Config helper:** used `django-environ` (the task allows pydantic-settings OR django-environ). Env doc §2 mentions `python-decouple`; chose django-environ as it natively reads the per-field `DB_*` vars in `.env.example` (no `DATABASE_URL`) with type casting. Noted here, not added to DECISIONS.md as it's within the task's stated options.
- **Test database:** `config/settings/test.py` uses in-memory SQLite + locmem cache so the suite runs without Postgres/Redis (per task's blocked-on-services rule). The dev/prod path still targets Postgres (psycopg3) + Redis. Verified the real path manually: brought up the Dockerized Postgres (on host port 55432 since host 5432/6379 were occupied by a pre-existing Docker process), ran `migrate`, then confirmed `GET /healthz` → 200 `{"status":"ok"}` and `GET /api/v1/config/public` → 200 `{"flags":{},"config":{}}` both via `runserver` and via the built `api.Dockerfile` image (gunicorn) on the compose network.
- **DRF exception handler:** left commented in `REST_FRAMEWORK` as a reserved hook for T-005 (not implemented here, per scope).

### Files touched (actual)
Added: `apps/api/pyproject.toml`, `apps/api/uv.lock`, `apps/api/manage.py`, `apps/api/conftest.py`, `apps/api/config/{__init__.py,urls.py,wsgi.py,asgi.py}`, `apps/api/config/settings/{__init__,base,dev,prod,test}.py`, `apps/api/khatir/__init__.py`, `apps/api/khatir/health/{__init__,apps,views,urls}.py`, `apps/api/tests/{__init__,test_healthz}.py`.
Updated: `infra/docker/api.Dockerfile`, `docker-compose.yml` (api service enabled, depends_on db+redis healthy).

## 15. Notes for the implementing agent
- Use the latest stable Django (6.x at time of writing) — verify on PyPI before pinning in uv.lock.
- `DJANGO_SETTINGS_MODULE` selected via `DJANGO_ENV` env (dev default).
- Keep the exception-handler slot wired so T-005 can drop in the standard error envelope.
- `config/public` returns empty `flags`/`config` now; later epics populate it.
