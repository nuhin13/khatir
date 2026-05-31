---
id: T-014
epic: EPIC-00
title: CI/CD GitHub Actions (lint+type+test per app)
layer: infra
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004, T-007, T-009]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-014 · CI/CD GitHub Actions (lint+type+test per app)

## 1. Feature goal
Set up GitHub Actions so every PR runs lint + type-check + tests for each affected app, and no PR merges to `main` without a green pipeline.

## 2. Business logic
Path-filtered jobs: only run an app's job when its files changed (keeps CI fast). Backend job spins up Postgres + Redis service containers. CI is the authoritative gate (pre-commit is local convenience).

## 3. What this task DOES
- `.github/workflows/ci.yml` with path-filtered jobs:
  - **api:** uv install → ruff check → mypy → pytest (with Postgres + Redis service containers); runs `makemigrations --check`.
  - **mobile:** flutter pub get → dart format --set-exit-if-changed → flutter analyze → flutter test.
  - **admin:** npm ci → eslint → tsc --noEmit → test → next build.
- Caching for uv, pub, npm.
- Branch protection guidance documented (require CI + 1 review before merge).
- A status badge added to README (T-016 finalizes).

## 4. What this task does NOT do
- No deployment (production deploy is later/infra/deploy).

## 5. Files & changes
### Add
- `.github/workflows/ci.yml`
- `infra/ci/` notes (branch protection setup) — optional
### Update
- `README.md` — CI badge placeholder
- remove `infra/ci/.gitkeep`
### Delete
- none

## 6. Database changes
CI runs `makemigrations --check` to catch missing migrations. No schema authored here.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
GitHub Actions runners only.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] api job: ruff + mypy + pytest + makemigrations --check with PG+Redis services
- [ ] mobile job: format-check + analyze + test
- [ ] admin job: eslint + tsc + test + build
- [ ] path filters so only changed apps run
- [ ] dependency caching
- [ ] green on a trivial PR
- [ ] branch protection documented

## 12. Test plan
### Manual QA
1. Open a PR touching only `apps/api` → only the api job runs and passes.
2. Introduce a lint error → CI fails.

## 13. Acceptance criteria
- [ ] CI runs the right jobs per changed paths.
- [ ] All three app pipelines pass on clean code.
- [ ] Missing migration fails CI.

## 14. Self-review
- [ ] Path filters correct
- [ ] Service containers healthy for api tests
- [ ] Caching effective
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use Postgres 17 + Redis 8 service containers for the api job, env wired to match `.env.example`.
- iOS build is not run in CI (needs macOS runner); Android analyze+test is sufficient for the mobile job at this stage — note this.
- Keep jobs independent so a mobile-only change doesn't wait on api.
