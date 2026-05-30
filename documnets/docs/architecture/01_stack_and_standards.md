# 01 · Stack & Standards

> Exact dependencies and the rules every agent must follow. When a task says "per coding standards," it means this file.

---

## 1. Version policy — ALWAYS LATEST STABLE

**Rule: use the latest *stable* release of every tool and library at the time you scaffold or add it.** Do not pin to old versions. Do not use beta/RC/canary/dev channels. "Stable" = the version the project officially marks Production/Stable, not pre-release.

When an agent adds or upgrades a dependency:
1. Check the official source (PyPI, pub.dev, npm, the project site) for the **current latest stable**.
2. Use that. Pin the exact resolved version in the lockfile (`uv.lock` / `pubspec.lock` / `package-lock.json`) for reproducibility.
3. Note the version actually used in the task's self-review.

**Anchors as of project start (May 2026)** — informational floor, not a cap. If a newer stable exists when you scaffold, use the newer one:

| Tool | Latest stable @ start | Channel |
|------|----------------------|---------|
| Python | 3.13.x | latest stable (3.14 ok once libs support it) |
| Django | 6.0.x | latest stable (6.0.5 at start) |
| Django REST Framework | 3.17.x | latest stable |
| Flutter | 3.44.x | stable channel |
| Dart | 3.11.x | ships with Flutter stable |
| Next.js | 16.x | latest stable (16.2.x at start) |
| React | 19.x | as bundled with Next 16 |
| Node | 22.x LTS | LTS only |
| PostgreSQL | 17.x | latest stable major |
| Redis | 8.x | latest stable |

> If any anchor here is older than what's current when you build, **prefer current**. This table is a floor, never a cap. The only reason to hold back is a hard incompatibility — if so, document it in `DECISIONS.md`.

### Upgrade discipline
- Patch releases: always take them.
- Minor/major: an agent may bump within a task if needed and CI stays green; otherwise leave a `chore` task.
- Security releases: apply immediately as their own `fix` task.

---

## 2. Dependency set (libraries — resolve latest stable, don't hand-pin)

### Backend (`apps/api/`)
- **Core:** Django, djangorestframework, djangorestframework-simplejwt
- **DB:** psycopg (v3), dj-database-url
- **Async/jobs:** celery, redis, django-celery-beat
- **Config:** pydantic-settings (or django-environ)
- **Storage:** boto3 (S3-compatible)
- **Security:** cryptography (field encryption)
- **PDF:** reportlab and/or weasyprint (decide in EPIC-05)
- **Dev/test:** pytest, pytest-django, factory-boy, ruff, mypy
- **Deps manager:** **uv** (`uv.lock` is the lockfile)

### Mobile (`apps/mobile/`)
- go_router · hooks_riverpod (+ riverpod_generator) · dio · freezed + json_serializable · flutter_secure_storage · intl + gen-l10n · fl_chart · flutter_map (+ latlong2, OSM tiles) · image_picker · cached_network_image · flutter_lints · build_runner

### Admin (`apps/admin/`)
- Next.js (App Router) · React · TypeScript (strict) · TailwindCSS · @tanstack/react-query · zod · react-hook-form (+ @hookform/resolvers) · recharts · lucide-react · next-intl

### AI Gateway (`services/ai-gateway/` — EPIC-14)
- FastAPI · pydantic · httpx · uvicorn — all latest stable.

### Infra
- Docker · Docker Compose v2 · GitHub Actions · PostgreSQL + Redis latest stable majors.

---

## 3. Coding standards — Python / Django

**Formatter & linter:** `ruff` (format + lint). Config in `apps/api/pyproject.toml`. Line length 100. **Deps:** `uv`.

- Type hints on every signature. `mypy` must pass.
- No business logic in views. Views: validate → call service → serialize. Logic in `services.py`.
- No raw SQL unless justified in a comment + reviewed.
- Every model: `__str__`, explicit `Meta.ordering`, `created_at`/`updated_at` via `TimeStampedModel`.
- Money: `DecimalField(max_digits=12, decimal_places=2)`. **Never float.**
- Datetime: tz-aware, UTC.
- Enums: Django `TextChoices`/`IntegerChoices`.
- Permissions: explicit DRF classes.
- Domain querysets go through `for_user(user)` enforcing row-level ownership.

**Test rule:** every endpoint ships ≥ 1 happy-path, 1 auth-failure, 1 validation-failure test.

---

## 4. Coding standards — Dart / Flutter

**Formatter:** `dart format` (100). **Linter:** `flutter_lints` + `analysis_options.yaml`.

- State: **Riverpod** only.
- Models: **freezed** + **json_serializable**.
- Networking: one `dio` instance via provider, auth + error interceptors.
- Routing: **go_router**, all routes in `app_router.dart`.
- Strings via gen-l10n ARB (`bn` default, `en`). No hardcoded strings.
- Theme tokens in `theme/`. No inline hex.
- Folder-by-feature.
- Every screen: loading / error / empty / data.

**Test rule:** ≥ 1 widget test for the primary screen + unit tests for non-trivial logic.

---

## 5. Coding standards — TypeScript / Next.js

**Formatter:** Prettier. **Linter:** ESLint (next + typescript). `strict: true`.

- App Router only; Server Components default, `"use client"` only when needed.
- Server state via **TanStack Query**.
- Validate API responses with **zod** at the boundary.
- Forms via **react-hook-form** + zod resolver.
- No `any`.
- Design tokens from shared Tailwind config.
- Every data component: loading + error + empty.

**Test rule:** critical admin flows get ≥ 1 integration test.

---

## 6. Git & PR conventions

**Branch:** `epic-NN/T-XXX-short-slug`.

**Commits — Conventional Commits + epic/task tag:**
```
feat(tenants): add NID OCR endpoint [EPIC-04 T-007]
fix(rent): correct reminder cadence off-by-one [EPIC-07 T-011]
chore(infra): bump postgres to latest stable [EPIC-00 T-002]
docs(epics): mark EPIC-03 complete
test(leases): add rent schedule edge cases [EPIC-06 T-005]
```
Types: `feat fix chore docs test refactor perf style`.

**One task = one branch = one PR.** PR title = task title + ID; description carries acceptance criteria as a checklist. CI (lint + type + test) must pass before merge. No direct push to `main`. **Squash merge**, keep `[EPIC-NN T-XXX]` tag.

---

## 7. Enum policy

**Never bare literals for fixed-value fields.** Canonical list in `enums.md`; backend `TextChoices`, Dart `enum`, TS union all match it. Wire = lowercase snake_case string. Add/change enum → update `enums.md` first, then all three surfaces.

---

## 8. Anti-patterns that fail review

- ❌ Pinning an old version when a newer stable exists. ❌ Beta/RC/canary channels.
- ❌ Float for money. ❌ Naive datetimes.
- ❌ Business logic in views / widgets / components.
- ❌ Hardcoded prices, limits, cadences, provider names (DB config instead).
- ❌ Hardcoded user-facing strings (use i18n).
- ❌ Inline hex colors (use theme tokens).
- ❌ Bare literals for status fields (use enums).
- ❌ Public endpoints returning reputation of identifiable people.
- ❌ Querysets not scoped to the requesting user.
- ❌ `setState` / `useEffect`+fetch for server data.
- ❌ Screens missing loading/error/empty states.
- ❌ Commit without `[EPIC-NN T-XXX]`.
- ❌ Raw NID payloads or unencrypted personal images.
- ❌ Merging without `make test && make lint` passing.
