# Khatir

<!-- CI badge: replace OWNER/REPO once the repo is published. -->
[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

**Khatir** is a property and tenancy management platform for Bangladesh landlords and
tenants. It digitises the manual paperwork of renting — tenant onboarding with NID capture,
DMP (Dhaka Metropolitan Police) tenant-information forms, lease and rent schedules, rent
collection, maintenance/expense tracking, and an owner dashboard — across a mobile app for
landlords/tenants and a web admin portal for operators.

This is a **mono-repo**: the Django/DRF backend, the Flutter mobile app, the Next.js admin
portal, and the shared design-token package all live in one tree with a single set of
developer commands (one `Makefile`, one `docker compose` stack).

---

## Monorepo layout

```
khatir/
├── apps/
│   ├── api/                 # Django + DRF backend (uv-managed, Python 3.13)
│   ├── mobile/              # Flutter app — landlord + tenant (Dart/Flutter)
│   └── admin/               # Next.js admin portal (App Router, Tailwind v4)
├── packages/
│   └── design-tokens/       # Shared color/spacing/radius/type tokens (Flutter + Tailwind)
├── infra/
│   └── scripts/             # tracker.py (task board), commit-msg checker, helpers
├── docker-compose.yml       # Local stack: Postgres, Redis, api, worker, beat, admin
├── Makefile                 # One set of verbs for the whole repo
├── .pre-commit-config.yaml  # ruff / dart / eslint+prettier / secret + commit-msg checks
├── .github/workflows/ci.yml # CI: lint + type + test per app
├── documnets/docs/          # Architecture, epic plan, design map (see note below)
├── CONTRIBUTING.md          # Branch/commit conventions, task loop, review + handoff
└── DECISIONS.md             # Architecture/process decision log
```

> Note: project docs live under `documnets/docs/` — the directory name is a pre-existing
> misspelling that is kept as-is to avoid breaking references. See `DECISIONS.md`.

---

## Prerequisites

| Tool | Version | Used by | Install |
|------|---------|---------|---------|
| Docker + Docker Compose | latest | full local stack (`make up`) | https://docs.docker.com/get-docker/ |
| [uv](https://docs.astral.sh/uv/) | latest | `apps/api` (Python 3.13, deps, pytest, ruff) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Flutter | 3.44.x (Dart SDK ≥ 3.12) | `apps/mobile` | https://docs.flutter.dev/get-started/install |
| Node.js | ≥ 20 LTS (with npm) | `apps/admin` (Next.js 16) | https://nodejs.org |
| Python 3 | 3.13 (host, for `make status`/tracker) | `infra/scripts/tracker.py` | system / pyenv |
| [pre-commit](https://pre-commit.com) | latest | git hooks | `uv tool install pre-commit` |

You do **not** need a local Python/Postgres/Redis to run the backend — `make up` runs it all
in containers. The host tools above are only needed for running an app outside Docker or for
the per-app `make` targets.

---

## Quickstart (clone → running in minutes)

```bash
git clone <repo-url> khatir
cd khatir

# 1. Environment: copy the template and fill in any secrets you have (works as-is for local).
cp .env.example .env

# 2. Bring up the full stack (Postgres, Redis, API, Celery worker + beat, admin).
make up

# 3. Apply database migrations.
make migrate

# 4. (optional) Create a Django superuser for the admin/Django admin.
make superuser
```

Once up:

- API health check: `curl http://localhost:8000/healthz` → `{"status": "ok"}`
- Admin portal: http://localhost:3000
- Tail logs: `make logs` · service status: `make ps` · stop: `make down`

Install pre-commit hooks once (keeps every commit clean — see CONTRIBUTING.md):

```bash
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### `make` targets

`make` (or `make help`) prints every target. The most-used ones:

| Target | What it does |
|--------|--------------|
| `make up` / `make down` | Start / stop the full docker compose stack |
| `make logs` / `make ps` / `make restart` | Tail logs / show status / restart services |
| `make migrate` / `make makemigrations` | Apply / generate Django migrations (api container) |
| `make superuser` / `make dbshell` | Create a Django superuser / open a `psql` shell |
| `make install` | Install deps for all three apps |
| `make test` | Run all three app test suites |
| `make lint` | Run all three linters |
| `make format` | Format code across all apps |
| `make status` | Task tracker: status counts + per-epic progress |
| `make next` | Next ready task (`make next LAYER=backend\|mobile\|admin\|infra`) |
| `make review-queue` | Tasks awaiting review |
| `make epic-report EPIC=00` | Completion report for an epic |

### Per-app: run / test / build

**Backend — `apps/api`** (uv-managed Django, runs on the host via `uv run`, no container needed):

```bash
make api-install   # cd apps/api && uv sync
make api-test      # cd apps/api && uv run pytest
make api-lint      # cd apps/api && uv run ruff check .
make api-shell     # Django shell
```

**Mobile — `apps/mobile`** (Flutter):

```bash
make mobile-install  # flutter pub get
make mobile-run      # flutter run
make mobile-test     # flutter test
make mobile-lint     # flutter analyze
```

**Admin — `apps/admin`** (Next.js):

```bash
make admin-install  # npm install
make admin-dev      # npm run dev   (http://localhost:3000)
make admin-build    # npm run build
make admin-test     # npm run test  (vitest run)
make admin-lint     # npm run lint  (eslint)
```

---

## Documentation

- **Architecture overview:** [documnets/docs/architecture/00_overview.md](documnets/docs/architecture/00_overview.md)
- **Stack & standards:** [documnets/docs/architecture/01_stack_and_standards.md](documnets/docs/architecture/01_stack_and_standards.md)
- **Project structure:** [documnets/docs/architecture/02_project_structure.md](documnets/docs/architecture/02_project_structure.md)
- **Env & config:** [documnets/docs/architecture/03_env_and_config.md](documnets/docs/architecture/03_env_and_config.md)
- **Coding conventions:** [documnets/docs/architecture/04_coding_conventions.md](documnets/docs/architecture/04_coding_conventions.md)
- **Epic plan (all work):** [documnets/docs/epics/_master_plan.md](documnets/docs/epics/_master_plan.md)
- **Live board:** [documnets/docs/epics/README.md](documnets/docs/epics/README.md) · regenerate with `make status`
- **How to contribute:** [CONTRIBUTING.md](CONTRIBUTING.md) · **Decision log:** [DECISIONS.md](DECISIONS.md)

---

## License

Proprietary — UNLICENSED. Copyright (c) 2026 Khatir. All rights reserved. See [LICENSE](LICENSE).
