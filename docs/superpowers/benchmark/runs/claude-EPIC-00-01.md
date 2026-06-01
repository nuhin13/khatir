# Benchmark Run — Claude Code — EPIC-00 + EPIC-01

- **Date / operator:** 2026-06-02 / main-thread orchestration (Claude Code)
- **Workspace:** `~/khatir-bench/claude`, branch `bench/claude`
- **Model / tier:** Claude Opus 4.8 (1M) main thread; general-purpose subagents per task (one role agent per task)
- **Execution mode:** dispatcher-driven, dependency-ordered; independent tasks run in parallel git worktrees, then merged
- **Wall-clock:** ~spread over the session (per-task agent durations 45s–1240s; heaviest were the Flutter theme/i18n and admin scaffold tasks)
- **Token usage:** ~1.6M subagent tokens total across 28 task agents (range ~22k–101k per task; backend/admin/mobile scaffolds were the most expensive)

## What was asked vs what was done
- **Asked:** Build all 28 tasks (EPIC-00 foundation = 16, EPIC-01 auth = 12) faithfully per each task's 15-section spec, with real verification (tests/lint/types/build), marking status + committing per task.
- **Done:** 28/28 tasks completed, each marked `status: done`, BOARD updated, committed with `T-XXX:` tag. All three surfaces real and verified.
- **Scope drift:** none material. Agents respected task boundaries (e.g. T-005 verify-only vs T-006 JWT issuance; T-011 auth-state vs T-012 routing). A few additive deviations (extra Makefile targets, completeness of design tokens) — all documented in each task's §14.

## Final verification (all green)
- **Backend (apps/api, Django 6 + DRF):** `uv run pytest` → **109 passed**; `ruff` clean; `mypy` clean (68 source files).
- **Mobile (apps/mobile, Flutter 3.44):** `flutter analyze` → No issues; `flutter test` → **41 passed**.
- **Admin (apps/admin, Next.js 16 + React 19):** `npm run build` → Compiled successfully (after `npm install`); lint + typecheck clean; vitest passing.
- **Dispatcher:** `--epics EPIC-00,EPIC-01` returns empty (all 28 done).

## Objective metrics (bench_metrics.py)
| metric | value |
|--------|-------|
| scoped_tasks | 28 |
| tasks_marked_done | 28 |
| completion_pct | 100.0 |
| task_tagged_commits | 28 |
| total_commits | 69 (incl. merges + the workflow harness commits) |

## Mistakes / retro (what the run surfaced)
1. **Dispatcher dot-notation bug (caught here, fixed in source).** Real task files write cross-epic deps as `EPIC-00.T-005` (dot); the dispatcher only resolved the slash form, so all 131 cross-epic-dep tasks were invisible. EPIC-01 showed zero ready tasks until fixed. Fix committed to source repo + backported.
2. **EPIC-08 duplicate task IDs (pre-existing, fixed earlier).** 8 IDs duplicated; would have silently collapsed.
3. **Cross-worktree `node_modules` / `uv` envs don't merge.** T-015 installed `@sentry/nextjs` in its worktree; after merge the dep was in `package.json` but not installed in the main workspace, so `next build` failed until `npm install`. Lesson for Phase C: after merging a worktree that added deps, re-install in the integration workspace before verifying. (No code defect.)
4. **Merge conflicts were frequent but trivial** on `BOARD.md` (every parallel task appends a line) and occasionally real on shared files (`views.py`, `settings/base.py` when T-006 + T-007 both edited auth). The T-006/T-007 code conflict required careful manual resolution; a conflict marker had eaten the `SIMPLE_JWT` closing brace — caught by an `ast.parse` syntax check + full test re-run (109 passed) before committing. Lesson: always syntax-check + re-run tests after a non-BOARD merge conflict.
5. **Doc inconsistencies the agents flagged (not fixed):** OTP length 6 (spec) vs 4 (prototype `otp` screen); a couple of architecture-doc mentions (python-decouple vs django-environ) that don't match the chosen stack. Worth a docs reconciliation pass.

## Quality observations (for the rubric)
- **Feature completion:** 28/28, every acceptance gate met with real tooling (no faked tests).
- **Test discipline:** strong — agents wrote/extended tests and actually ran them; backend grew to 109 tests, mobile 41.
- **Plan adherence:** high — task boundaries respected, deviations documented in §14.
- **Self-recovery:** good — agents caught and fixed their own mid-task bugs (Tailwind CJS/ESM, l10n gen path, greedy regex in tracker, mypy strictness) without human help.
- **Cost:** heaviest scaffolding tasks ran 70k–101k tokens; mechanical/seed tasks ~22k–40k. Per-task isolation kept context small as designed.

## Raw scores (fill against RUBRIC.md when comparing platforms)
| Metric | Raw 0–10 |
|--------|----------|
| Feature completion % | |
| Tests pass ratio | |
| Rework / mistake ratio | |
| Plan adherence | |
| Token + $ cost | |
| Wall-clock | |
| Code quality | |
| Self-recovery | |
