# EPIC-00 · Foundation & Scaffold — Completion Report

**Status:** done
**Completed:** 2026-06-02
**Tasks:** 16 / 16 done
**External services:** none (Sentry optional)

---

## Summary

EPIC-00 stands up the entire Khatir mono-repo skeleton: folder structure, local docker
stack, the three app scaffolds (Django/DRF API, Flutter mobile, Next.js admin), the shared
design-tokens package, the Makefile of dev + tracker verbs, pre-commit hooks, CI, and
observability. After this epic, `make up` runs the full stack locally and any agent can
scaffold feature work into a known, consistent structure. No product features were built —
this is structure, tooling, and conventions made real in code.

## Tasks delivered

| Task | Title | Layer | Status |
|------|-------|-------|--------|
| T-001 | Initialize mono-repo structure & root files | infra | done |
| T-002 | Env conventions & `.env.example` | infra | done |
| T-003 | Docker-compose local stack (Postgres, Redis) | infra | done |
| T-004 | Django API scaffold (settings, uv, ruff, healthz) | backend | done |
| T-005 | Django `core` app (base models, envelope, exceptions) | backend | done |
| T-006 | Celery + Celery Beat wiring | backend | done |
| T-007 | Flutter app scaffold (structure, router skeleton) | mobile | done |
| T-008 | Flutter theme tokens + i18n (bn/en) | mobile | done |
| T-009 | Next.js admin scaffold (App Router, Tailwind, shells) | admin | done |
| T-010 | Shared design-tokens package | packages | done |
| T-011 | Makefile (dev + tracker commands) | infra | done |
| T-012 | Tracker scripts (status/next/review-queue/epic-report) | infra | done |
| T-013 | Pre-commit hooks (ruff, dart format, eslint/prettier) | infra | done |
| T-014 | CI/CD GitHub Actions (lint+type+test per app) | infra | done |
| T-015 | Observability (Sentry + structured logging) | cross-cutting | done |
| T-016 | Root docs wiring (README, CONTRIBUTING, DECISIONS) | docs | done |

## Epic-level acceptance criteria

- [x] `make up` brings up Postgres + Redis + API + admin locally (docker compose: `db`,
  `redis`, `api`, `worker`, `beat`, `admin`).
- [x] `GET /healthz` returns `{status: ok}` (T-004).
- [x] Flutter app builds and runs to the placeholder screen with Bangla default + English
  toggle (T-007/T-008).
- [x] Next.js admin builds and serves the placeholder login + dashboard shell (T-009).
- [x] `make test` and `make lint` pass for all three apps.
- [x] CI runs lint + type + test per app on PR (T-014).
- [x] `make status` and `make next` parse task frontmatter and report state (T-012).
- [x] Pre-commit hooks block unformatted commits + bad commit messages (T-013).
- [x] Shared design tokens consumed by both Flutter and admin (T-010 → T-008/T-009).

## Key decisions (see `DECISIONS.md`)

- uv as the Python manager; backend commands run host-side via `uv run`.
- Latest-stable version policy with lockfiles; ESLint pinned to 9.x (Next ecosystem
  incompatibility with ESLint 10).
- Single mono-repo with one Makefile + one compose stack.
- Single shared `packages/design-tokens` consumed by Flutter and Tailwind.
- Celery runs eagerly in tests (`CELERY_TASK_ALWAYS_EAGER`), real worker/beat at runtime.
- Docs kept under the pre-existing `documnets/docs/` path (misspelling retained on purpose).

## Onboarding artifacts (T-016)

- `README.md` — intro, monorepo map, prerequisites, `make up` quickstart, per-app
  run/test/build, links to architecture + the master plan, CI badge.
- `CONTRIBUTING.md` — branch/commit conventions, pre-commit, the task-execution loop,
  peer review + handoff, PR/CI gate.
- `DECISIONS.md` — EPIC-00 decision log.

## Notes / follow-ups

- CI badge in `README.md` still points at `OWNER/REPO`; swap to the real slug when the repo
  is published.
- pre-commit git hooks are not yet installed in this workspace (sample hooks only); run the
  two `pre-commit install` commands from the README/CONTRIBUTING after cloning.
- Human sign-off (`verified`) per `_handoff_protocol.md` is the remaining gate to fully close
  the epic.
