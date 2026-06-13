# Claude Code Progress Review — 2026-06-04

## Purpose

Independent review of the work currently committed on branch `bench/claude`.
The goal is to compare tracker claims and task intent against what is actually
implemented and verifiable.

This review is intentionally not a task completion update. It does not change
task frontmatter, `BOARD.md`, or commit status.

## Executive Summary

The backend implementation for onboarding/auth and properties is mostly solid at
runtime: the backend test suite passes with 283 tests. The project is not
end-to-end ready because the mobile app still fails analyze/test, backend mypy
fails, and several tracker/task documents are marked done despite unmet
checklist or verification gates.

Update after the first audit pass: the worktree now contains uncommitted mobile
changes that appear to address the original `latlong2` dependency conflict.
With those pending changes present, Flutter gets past dependency solving but
still fails at compile/analyze, so the mobile DoD gate remains blocked.

Current reliable status:

- `EPIC-00`: marked complete, but has process/verification issues.
- `EPIC-01`: backend auth path is credible; mobile auth cannot currently be
  verified because Flutter dependency resolution fails.
- `EPIC-02`: backend profile/role base is credible; mobile role/profile work is
  implemented but correctly still `in-progress`.
- `EPIC-03`: backend properties APIs are credible at runtime; mobile properties
  work is implemented but correctly still `in-progress` and has a navigation
  gap.
- `EPIC-04` through `EPIC-26`: inventoried as `todo`; no implementation review
  was needed beyond confirming tracker state.

## What Was Checked

Tracker and task state:

- `BOARD.md`
- task frontmatter/status across `documnets/docs/epics/EPIC-*`
- `workflow/board_schema.md`
- `make status`
- `make review-queue`
- `python3 infra/scripts/tracker.py epic-report 00`
- `python3 infra/scripts/tracker.py epic-report 03`

Backend:

- Django settings, URLs, serializers, services, permissions, selectors, models
- Auth/OTP/JWT/profile code
- Properties building/unit CRUD, portfolio aggregation, unit generation parity
- Backend tests under `apps/api/khatir/**/tests`
- CI backend gates: pytest, ruff, mypy, makemigrations check

Mobile:

- `apps/mobile/pubspec.yaml`
- router/auth/profile/properties data layers
- onboarding/auth/role shell screens at source level
- landlord home, portfolio, wizard, unit detail source and tests
- Flutter dependency resolution and test command

Admin:

- package scripts and dependency install
- Next build, TypeScript, ESLint, Vitest
- Tailwind design-token package resolution
- npm audit

Infra/process:

- `.github/workflows/ci.yml`
- `.pre-commit-config.yaml`
- `infra/scripts/check_commit_msg.py`
- `docker-compose.yml`
- `.env.example`, README/CONTRIBUTING quickstart references

## Verification Results

Passed:

- `uv run pytest` in `apps/api`: 283 passed
- `uv run ruff check .` in `apps/api`: passed
- `DJANGO_ENV=test uv run python manage.py makemigrations --check --dry-run`:
  no changes detected
- `npm run lint` in `apps/admin`: passed
- `npm run typecheck` in `apps/admin`: passed
- `npm run test -- --run` in `apps/admin`: 2 passed
- `npm run build` in `apps/admin`: passed

Failed or blocked:

- `flutter test` in `apps/mobile`: dependency solving now progresses with the
  pending mobile changes, but compilation fails.
- `flutter analyze` in `apps/mobile`: 19 issues.
- `uv run mypy .` in `apps/api`: 53 errors in properties tests.
- `npm audit --audit-level=moderate` in `apps/admin`: 2 moderate advisories
  through `next`/`postcss`.
- `docker compose config --quiet`: fails without a local `.env`; README does
  document `cp .env.example .env`, so this is a setup prerequisite rather than
  a code defect.

## Findings

### P0 — Mobile Analyze/Test Still Fails

Original audit blocker:

- `flutter_map ^8.3.0` required `latlong2 ^0.9.1`
- the app pinned `latlong2 ^0.10.1`

Current worktree note:

- uncommitted mobile changes now set `latlong2` to `^0.9.1`
- Flutter proceeds further, but compilation still fails

Impact:

- All mobile tasks that claim analyze/test coverage are unverifiable.
- CI mobile job will still fail.
- EPIC-01, EPIC-02, and EPIC-03 mobile work cannot be considered DoD-complete.

Main current compile failures:

- `BuildingsController.update`, `BuildingUnitsController.update`, and
  `UnitDetailController.update` collide with Riverpod `AsyncNotifierBase.update`.
- `Step4Review` references `PortfolioScreen.routePath`, but the visible import
  only exposes `areaLabel`.
- `KMapPicker` references missing localization getters:
  `map_picker_attribution` and `map_picker_tap_hint`.
- `flutter analyze` reports 19 issues, mostly null-aware collection element
  lints plus test warnings.

Action:

1. Keep the `latlong2` constraint compatible with `flutter_map`.
2. Rename controller methods that collide with Riverpod's `update`, for example
   `updateBuilding`, `updateUnit`, or `patchUnit`.
3. Fix `Step4Review` import/reference for `PortfolioScreen.routePath`.
4. Add/regenerate the missing map picker localization keys.
5. Clean analyzer warnings.
6. Run `flutter pub get`, `dart format --set-exit-if-changed .`,
   `flutter analyze`, and `flutter test`.
7. Only then update mobile task statuses.

### P0 — Backend Mypy Gate Fails

Runtime backend tests pass, but `uv run mypy .` fails with 53 errors in:

- `khatir/properties/tests/test_unit_api.py`
- `khatir/properties/tests/test_building_api.py`
- `khatir/properties/tests/test_portfolio.py`

Most failures are typing issues around factory return types and optional
response data indexing.

Impact:

- CI backend job will fail because mypy is required.
- Task checklists claiming `ruff + mypy clean` are inaccurate for properties.

Action:

1. Fix factory/test typing in properties tests.
2. Avoid unsafe `resp.data[...]` indexing without narrowing where mypy requires it.
3. Re-run `uv run mypy .`.
4. Re-run `uv run pytest`.

### P1 — Portfolio Add-Building CTA Is Not Wired To Wizard

`EPIC-03/T-012` says add-building should navigate to `/properties/add`.
The route exists in `app_router.dart`, but `PortfolioScreen._addBuilding`
still shows only a snackbar.

Impact:

- The EPIC-03 properties flow is not end-to-end from portfolio to add-building.
- Widget tests do not catch this because they assert the CTA renders, not that
  it navigates to the wizard.

Action:

1. Change `PortfolioScreen._addBuilding` to `context.pushNamed('addBuilding')`
   or `context.push('/properties/add')`.
2. Update `portfolio_screen_test.dart` to assert navigation to the wizard route.
3. Re-run mobile tests after dependency resolution.

### P1 — Tracker Marks Some Work Done Without DoD Evidence

Example: `EPIC-00/T-014-ci-cd.md` has `status: done`, but its implementation
checklist, acceptance criteria, and self-review boxes remain unchecked.

Impact:

- `make status` overstates verified completion.
- Agents may build on tasks that were never fully closed.

Action:

1. Audit all `status: done` tasks with unchecked checklist or acceptance boxes.
2. Either verify and check the boxes with evidence, or revert status to
   `in-progress` and add a blocker to `BOARD.md`.
3. Add a tracker guard that flags `status: done` with unchecked acceptance or
   self-review items.

### P1 — Commit Message Hook Conflicts With Agent Contract

The agent contract requires:

- `T-YYY: <imperative summary>`

The commit hook requires:

- Conventional Commit subject
- `[EPIC-NN T-XXX]` tag for feat/fix/refactor/perf/test

Existing task commits use the agent-contract format.

Impact:

- If hooks are installed, future agent commits can be blocked while following
  the documented agent protocol.

Action:

1. Pick one commit standard.
2. Update either `AGENTS.md` / `workflow/CORE.md` or
   `infra/scripts/check_commit_msg.py`.
3. Add tests for valid task-style commit messages.

### P2 — Admin Has Moderate Dependency Advisories

`npm audit` reports a moderate `postcss` advisory through `next`.

Impact:

- Current admin build/test/lint/typecheck pass.
- Security posture should be revisited before production exposure.

Action:

1. Track upstream Next/PostCSS patched versions.
2. Upgrade when a non-breaking fix is available.
3. Avoid `npm audit fix --force` without review because npm suggests a breaking
   downgrade path.

## Epic-by-Epic Review

### EPIC-00 — Foundation & Scaffold

What the epic says:

- Establish monorepo, env, Docker, backend scaffold, mobile scaffold, admin
  scaffold, tokens, Makefile, tracker, pre-commit, CI, observability, docs.

What is developed:

- Foundation files exist.
- Backend and admin scaffolds are runnable/testable.
- CI workflow exists with app-specific jobs.
- Pre-commit config exists.
- Design-token package exists and is consumed by apps.

Review verdict:

- Functionally useful foundation, but not fully verified.
- Mobile scaffold is blocked by compile/analyze/test failures.
- CI task status is ahead of its own checklist.
- Commit hook conflicts with agent commit protocol.

Action:

1. Fix mobile compile/analyze/test failures.
2. Fix backend mypy failures.
3. Align commit hook with agent protocol.
4. Re-audit `status: done` tasks with unchecked checklist items.

### EPIC-01 — Onboarding & Authentication

What the epic says:

- OTP auth, phone entry, OTP entry, JWT/session handling, splash routing, config
  seed, notification sender, rate limiting.

What is developed:

- Backend OTP/JWT endpoints, throttling, user model, auth services, and tests are
  implemented.
- Mobile auth/onboarding source exists with repository/controller/screens/tests,
  but the whole mobile suite is blocked by current compile failures in shared
  properties code.

Review verdict:

- Backend side is credible and pytest-covered.
- Mobile side cannot be verified until Flutter compile/analyze/test pass.

Action:

1. After mobile compile fixes, run `flutter analyze` and `flutter test`.
2. Add one real end-to-end auth smoke path when a test environment can issue a
   dev OTP deterministically.

### EPIC-02 — Role & Profile

What the epic says:

- Profile read/update endpoints, role permissions, Flutter profile repo, role
  shells, role chooser, bottom nav, More menu, router guards.

What is developed:

- Backend profile and role permission base exists and is pytest-covered.
- Mobile role/profile/shell/router code exists.
- Mobile tasks are marked `in-progress`, which is correct because analyze/test
  do not pass.

Review verdict:

- Backend is acceptable pending global mypy cleanup.
- Mobile needs verification after Flutter dependency fix.

Action:

1. Verify mobile role/profile flows after mobile compile fixes.
2. Add tests for role switching from More menu through `/profile` to router
   redirect behavior.

### EPIC-03 — Properties & Units

What the epic says:

- Building/unit models, scoping, CRUD APIs, portfolio endpoint, area config,
  Flutter data layer, map picker, landlord home, add-building wizard, portfolio
  screen, unit detail, UI/API unit-generation parity.

What is developed:

- Backend models/scoping/CRUD/portfolio/area config are implemented and pytest
  passes.
- Mobile data layer, map picker, home, wizard, portfolio, unit detail, and
  parity tests exist but remain `in-progress`.

Review verdict:

- Backend behavior is strong at runtime.
- Backend mypy fails in properties tests.
- Mobile cannot pass compile/analyze/test yet.
- Portfolio add-building CTA still does not navigate to the wizard.

Action:

1. Fix backend mypy failures.
2. Fix mobile compile/analyze/test failures.
3. Wire portfolio add-building CTA to `/properties/add`.
4. Run mobile analyze/test.
5. Re-run parity tests on both backend and Flutter.

### EPIC-04 through EPIC-26

What the epics say:

- Tenant management, DMP form, lease/rent, rent collection, maintenance,
  dashboards, pricing, admin modules, AI, notifications, compliance, tenant app,
  manager app, chatbot, gatekeeper, export, and related privacy/safety features.

What is developed:

- Tracker shows these as `todo`.

Review verdict:

- No implementation was reviewed because there is no completed work in these
  epics yet.

Action:

1. Do not start downstream epics that depend on mobile until the mobile
   analyze/test gate is green.
2. Prioritize the MVP path after EPIC-03 is verified: tenant/NID, DMP form,
   lease/rent schedule, rent collection.

## Recommended Action Plan

### Immediate Blockers

1. Fix mobile compile/analyze/test failures.
2. Run and pass `flutter pub get`, `flutter analyze`, `flutter test`.
3. Fix backend mypy errors.
4. Re-run backend full gate: `ruff`, `mypy`, `makemigrations --check`, `pytest`.
5. Wire portfolio add-building CTA to the wizard and add a navigation test.

### Tracker and Process Cleanup

1. Audit `status: done` tasks with unchecked DoD boxes.
2. Correct `EPIC-00/T-014` status or checklist evidence.
3. Align commit message policy between `AGENTS.md` and `check_commit_msg.py`.
4. Add tracker validation for done-task checklist integrity.

### End-to-End Coverage

1. Add backend API smoke tests for auth → profile → building → unit → portfolio.
2. Add mobile integration/widget flow for role selection → landlord home →
   portfolio → add-building wizard.
3. Add admin smoke only when real admin features are built beyond scaffold.
4. Run full CI locally before marking blocked mobile tasks done.

## Final Recommendation

Do not treat the repo as MVP-ready yet. Treat it as a partially built foundation
with a strong backend start and an unverified mobile layer.

The next engineering milestone should be:

> Make CI green across backend, mobile, and admin, then re-close EPIC-00 through
> EPIC-03 based on actual passing gates rather than task checkboxes.
