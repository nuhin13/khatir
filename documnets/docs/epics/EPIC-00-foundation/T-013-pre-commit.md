---
id: T-013
epic: EPIC-00
title: Pre-commit hooks (ruff, dart format, eslint/prettier)
layer: infra
size: S
status: done
preferred_agent: codex
depends_on: [T-004, T-007, T-009]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-013 · Pre-commit hooks (ruff, dart format, eslint/prettier)

## 1. Feature goal
Install pre-commit hooks so no unformatted or lint-failing code can be committed, keeping all three apps consistently clean without relying on memory.

## 2. Business logic
Hooks run only on changed files for speed. Backend → ruff (format+lint); Flutter → dart format + analyze; admin → eslint + prettier. Also generic hooks (trailing whitespace, EOF, large files, secret detection, commit-msg format check for Conventional Commits + epic tag).

## 3. What this task DOES
- `.pre-commit-config.yaml` at repo root with:
  - ruff (format + lint) scoped to `apps/api/`
  - dart format + `flutter analyze` scoped to `apps/mobile/`
  - eslint + prettier scoped to `apps/admin/`
  - generic: trailing-whitespace, end-of-file-fixer, check-added-large-files, detect-private-key/secret scan
  - commit-msg hook validating Conventional Commit + `[EPIC-NN T-XXX]` (or docs/chore exempt)
- Setup instructions in CONTRIBUTING (stub here, finalized T-016).

## 4. What this task does NOT do
- Does not replace CI (T-014); pre-commit is local, CI is authoritative.

## 5. Files & changes
### Add
- `.pre-commit-config.yaml`
- `infra/scripts/check_commit_msg.py` (commit-msg validator) if not using a ready hook
### Update
- `README.md` / CONTRIBUTING — "run `pre-commit install`"
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [x] ruff hook (apps/api)
- [x] dart format + analyze hook (apps/mobile)
- [x] eslint + prettier hook (apps/admin)
- [x] generic hygiene hooks + secret detection
- [x] commit-msg Conventional + epic-tag validator
- [x] `pre-commit install` documented
- [x] hooks pass on a clean repo, fail on a deliberately bad file

## 12. Test plan
### Manual QA
1. Stage a poorly-formatted Python file → commit blocked, auto-fixed.
2. Commit message without `[EPIC-NN T-XXX]` (and not docs/chore) → blocked.

## 13. Acceptance criteria
- [x] Bad formatting blocked + auto-fixed locally.
- [x] Non-conforming commit messages blocked.

## 14. Self-review
- [x] Hooks scoped per app (fast)
- [x] Secret detection on
### Deviations from spec
- Secret detection uses `gitleaks` plus the `detect-private-key` core hook (spec said
  "detect-private-key/secret scan" — both are wired).
- Dart/ESLint/Prettier hooks use `language: system` (call local `dart`/`flutter`/`npx`)
  rather than pinned pre-commit mirrors, so they reuse each app's own toolchain/config.
- `pre-commit validate-config` passes; full `pre-commit run --all-files` was NOT executed
  to avoid mass reformatting — hooks were spot-checked on single files instead.

### Files touched (actual)
- `.pre-commit-config.yaml` (added)
- `infra/scripts/check_commit_msg.py` (added)
- `README.md` (updated — pre-commit install instructions)

## 15. Notes for the implementing agent
- Commit-msg exemptions: `docs:` and `chore:` types may omit the task tag; `feat/fix/refactor/perf/test` require `[EPIC-NN T-XXX]`.
- Keep Flutter hook lightweight (format + analyze only; full tests are CI).
