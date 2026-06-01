# Khatir

<!-- CI badge placeholder — replace OWNER/REPO once the repo is published (T-016 finalizes). -->
[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

Khatir is a property and tenancy management platform (mono-repo). It houses the Django/DRF
backend (`apps/api`), the Flutter mobile app (`apps/mobile`), and the Next.js admin portal
(`apps/admin`), plus shared packages and deployment infra. This is a stub — full setup and
run instructions land in T-016.

## Pre-commit hooks

This repo uses [pre-commit](https://pre-commit.com) to keep all three apps clean. After
cloning, run once:

```bash
pip install pre-commit            # or: uv tool install pre-commit
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

Hooks run on changed files only: ruff (`apps/api`), dart format + analyze (`apps/mobile`),
eslint + prettier (`apps/admin`), generic hygiene, secret detection, and a Conventional
Commit + `[EPIC-NN T-XXX]` message check. Full setup lands in T-016.

See the architecture overview: [docs/architecture/00_overview.md](documnets/docs/architecture/00_overview.md).
