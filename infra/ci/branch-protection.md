# Branch protection (main)

CI (`.github/workflows/ci.yml`) is the authoritative merge gate. Pre-commit hooks
are local convenience only and must not be relied on for enforcement.

## Required settings on `main`

In **Settings → Branches → Branch protection rules**, add a rule for `main`:

- [x] **Require a pull request before merging**
  - [x] Require approvals: **1**
  - [x] Dismiss stale pull request approvals when new commits are pushed
- [x] **Require status checks to pass before merging**
  - [x] Require branches to be up to date before merging
  - Required status check: **`CI`** (the aggregate job — green only when every
    triggered app job passed; skipped app jobs do not block)
- [x] **Require conversation resolution before merging**
- [x] Do not allow bypassing the above settings

## Why an aggregate `CI` check

Per-app jobs (`api`, `mobile`, `admin`) are path-filtered, so they are *skipped*
on PRs that don't touch their app. GitHub branch protection cannot require a check
that may legitimately be skipped, so the workflow exposes a single `CI` job that
depends on all three and fails if any triggered job failed. Require **`CI`** only.

## Path filtering

The `changes` job (`dorny/paths-filter`) computes which apps changed; each app job
runs only when its `apps/<app>/**` paths (or the workflow file) changed. This keeps
a mobile-only PR from waiting on the backend pipeline and vice versa.

## Service containers (api job)

The `api` job runs Postgres 17 and Redis 8 service containers. Env vars are wired to
match `.env.example` (`DB_*`, `REDIS_URL`, `CELERY_*`). `makemigrations --check`
catches missing migrations before tests run.
