# EPIC-00 · Foundation & Scaffold

**Phase:** — (pre-product) · **Status:** todo · **Depends on:** none
**Tasks:** 16 · **External services:** none (Sentry optional)

---

## Business goal

Stand up the entire mono-repo skeleton so all feature work has a home. No product features — just structure, tooling, local dev environment, CI, and the conventions made real in code. After this epic, `make up` runs the full stack locally and any agent can scaffold a feature into a known, consistent structure.

## User-visible outcome

Nothing user-facing. The "users" of this epic are the engineers/agents: they get a running local stack, a green CI pipeline, and a repo that already embodies the architecture docs.

## Scope

**In scope**
- Mono-repo folder structure per `02_project_structure.md`.
- Docker-compose local environment (Postgres, Redis).
- Django API scaffold (settings split, core app, Celery, health check).
- Flutter app scaffold (structure, theme tokens, router skeleton, i18n bn/en).
- Next.js admin scaffold (App Router, Tailwind, placeholder login + dashboard shell).
- Shared design-tokens package.
- Makefile with all dev + tracker commands.
- Tracker scripts (`make status/next/review-queue/epic-report`).
- Pre-commit hooks, CI/CD, observability.

**Out of scope**
- Any auth logic (EPIC-01), any models beyond base classes, any real screens beyond placeholders.

## Dependencies

- Prerequisite epics: none (this is the first).
- External: none required to build. (Sentry DSN optional; WhatsApp/EC/MFS onboarding should be *started* in parallel but don't block this epic.)
- Design assets: Notun Din palette from `docs/logos/` and `ui/KhatirMobile.jsx` tokens.

## Data-model changes

Only base classes (`TimeStampedModel`, `SoftDeleteModel`) and the `core` app. No domain tables.

## API surface

- `GET /healthz` → `{ "status": "ok" }` (no auth).
- `GET /api/v1/config/public` → empty-but-valid envelope (filled by later epics).

## UI screens

- Flutter: a single placeholder splash/home confirming theme + i18n load.
- Admin: placeholder `/login` + empty dashboard shell.

## Feature flags introduced

None (the `featureflags` app is built in EPIC-13). EPIC-00 only lays the `core` foundation.

## Admin-portal config keys

None yet. `SystemConfig` table/accessor pattern is created in `core` so later epics can seed keys.

## Test strategy

- Backend: `pytest` runs, `GET /healthz` test passes, core base-model tests.
- Flutter: `flutter test` runs, one widget test for the placeholder screen.
- Admin: `npm test`/`vitest` runs, builds clean.
- CI executes all three on PR.

## Acceptance criteria (epic-level)

- [ ] `make up` brings up Postgres + Redis + API + admin locally.
- [ ] `GET /healthz` returns `{status: ok}`.
- [ ] Flutter app builds and runs on Android + iOS to the placeholder screen with Bangla default + English toggle.
- [ ] Next.js admin builds and serves the placeholder login + dashboard shell.
- [ ] `make test` and `make lint` pass for all three apps.
- [ ] CI is green on a PR.
- [ ] `make status` and `make next` correctly parse task frontmatter and report state.
- [ ] Pre-commit hooks block unformatted commits.
- [ ] Shared design tokens consumed by both Flutter and admin.

## Task list

| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Initialize mono-repo structure & root files | infra | S | — |
| T-002 | Env conventions & `.env.example` | infra | XS | T-001 |
| T-003 | Docker-compose local stack (Postgres, Redis) | infra | S | T-001, T-002 |
| T-004 | Django API scaffold (settings, uv, ruff, healthz) | backend | M | T-003 |
| T-005 | Django `core` app (base models, envelope, exceptions) | backend | M | T-004 |
| T-006 | Celery + Celery Beat wiring | backend | S | T-004 |
| T-007 | Flutter app scaffold (structure, router skeleton) | mobile | M | T-001 |
| T-008 | Flutter theme tokens + i18n (bn/en) | mobile | M | T-007, T-010 |
| T-009 | Next.js admin scaffold (App Router, Tailwind, shells) | admin | M | T-001, T-010 |
| T-010 | Shared design-tokens package | packages | S | T-001 |
| T-011 | Makefile (dev + tracker commands) | infra | S | T-004, T-007, T-009 |
| T-012 | Tracker scripts (status/next/review-queue/epic-report) | infra | M | T-001 |
| T-013 | Pre-commit hooks (ruff, dart format, eslint/prettier) | infra | S | T-004, T-007, T-009 |
| T-014 | CI/CD GitHub Actions (lint+type+test per app) | infra | M | T-004, T-007, T-009 |
| T-015 | Observability (Sentry + structured logging) | cross-cutting | S | T-004, T-007, T-009 |
| T-016 | Root docs wiring (README, CONTRIBUTING, DECISIONS) | docs | S | all above |

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Tooling version drift | "Latest stable" policy + lockfiles pin exact resolved versions |
| Agent invents non-standard folders | `02_project_structure.md` is the law; T-001 creates the skeleton so agents fill, not invent |
| CI flakiness blocks progress | Keep EPIC-00 CI minimal (lint+type+test); expand later |
| Flutter iOS build needs macOS | Note in task; Android-first acceptable for dev, iOS verified on a Mac runner/locally |
