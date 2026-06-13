---
id: T-001
epic: EPIC-00
title: Initialize mono-repo structure & root files
layer: infra
size: S
status: done
preferred_agent: claude-code
depends_on: []
blocks: [T-002, T-003, T-007, T-009, T-010, T-012]
external_services: []
feature_flags: []
started_at: 2026-06-02
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Initialize mono-repo structure & root files

## 1. Feature goal
Create the empty mono-repo skeleton exactly as defined in `docs/architecture/02_project_structure.md`, plus the root-level files every repo needs, so all later work has a known home.

## 2. Business logic
No business logic. This is pure structure. The folder layout is the law from `02_project_structure.md` — do not invent new top-level folders.

## 3. What this task DOES
- Create the top-level folder tree: `apps/`, `services/`, `infra/`, `packages/`, `docs/`.
- Create placeholder `.gitkeep` in empty dirs (`services/`, `infra/docker/`, `infra/scripts/`, `infra/ci/`, `infra/deploy/`, `packages/`).
- Move the existing `docs/` content (product specs, architecture, logos, epics) into `docs/` if not already there.
- Create root files: `README.md` (stub — fleshed out in T-016), `.gitignore`, `DECISIONS.md` (with a first entry), `.editorconfig`, `LICENSE` (proprietary/UNLICENSED placeholder).
- Initialize git (`git init`) if not already a repo; create `main` branch.

## 4. What this task does NOT do
- No app scaffolding (those are T-004, T-007, T-009).
- No Docker, no Makefile (T-003, T-011).

## 5. Files & changes

### Add
- `apps/.gitkeep`, `services/.gitkeep`, `infra/docker/.gitkeep`, `infra/scripts/.gitkeep`, `infra/ci/.gitkeep`, `infra/deploy/.gitkeep`, `packages/.gitkeep`
- `README.md` — one-paragraph stub + link to `docs/architecture/00_overview.md`
- `.gitignore` — Python, Node, Flutter, Docker, env, IDE, OS entries
- `DECISIONS.md` — header + entry: "2026-XX-XX · Mono-repo single-repo layout chosen (see architecture 02)."
- `.editorconfig` — UTF-8, LF, final newline, 2-space for yaml/json, 4-space python, 2-space dart/ts
- `LICENSE` — UNLICENSED / proprietary placeholder

### Update
- Ensure `docs/` (already containing architecture/, product/, logos/, epics/) sits at repo root.

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
- [x] Top-level folders created per architecture 02 (apps/, services/, infra/{docker,scripts,ci,deploy}/, packages/)
- [x] `.gitkeep` in empty dirs
- [x] `docs/` present at root with architecture/product/logos/epics (pre-existing under `documnets/` — see DECISIONS.md)
- [x] `.gitignore` covers Python/Node/Flutter/Docker/env/IDE/OS
- [x] `README.md` stub created
- [x] `DECISIONS.md` created with first entry
- [x] `.editorconfig` created
- [x] `LICENSE` placeholder created
- [x] git initialized (pre-existing clone), branch `bench/claude` (benchmark branch, not `main`)

## 12. Test plan
### Automated
- none (structure only)
### Manual QA
1. `tree -L 2 -a` shows the exact structure from architecture 02.
2. `git status` is clean after an initial commit.

## 13. Acceptance criteria
- [x] Folder tree matches `02_project_structure.md` top level exactly.
- [x] Root files present.
- [x] Repo is a valid git repo (on benchmark branch `bench/claude`, not `main` — see deviations).

## 14. Self-review
- [x] Structure matches architecture doc
- [x] No extra top-level folders invented
### Deviations from spec
- Docs were NOT moved into a new root `docs/` folder. The architecture/product/logos/epics tree pre-exists under `documnets/` (misspelled dir). Per task instruction this existing tree was left untouched; `apps/`, `services/`, `infra/`, `packages/` were created alongside it. Recorded in DECISIONS.md.
- `git init` was NOT run — repo is a pre-existing clone. Active branch is `bench/claude` (benchmark branch), not `main`.
- `.gitignore` already existed and was extended (Flutter/Dart, Docker, lockfile-keep note) rather than recreated.
### Files touched (actual)
- Created: `apps/.gitkeep`, `services/.gitkeep`, `infra/docker/.gitkeep`, `infra/scripts/.gitkeep`, `infra/ci/.gitkeep`, `infra/deploy/.gitkeep`, `packages/.gitkeep`, `README.md`, `DECISIONS.md`, `.editorconfig`, `LICENSE`
- Updated: `.gitignore`, this task file, `BOARD.md`

## 15. Notes for the implementing agent
- The `.gitignore` must include: `.env`, `*.pyc`, `__pycache__/`, `.venv/`, `node_modules/`, `.dart_tool/`, `build/`, `*.iml`, `.idea/`, `.vscode/`, `.DS_Store`, `uv.lock` keep (do NOT ignore lockfiles), `*.local`.
- Do NOT gitignore lockfiles (`uv.lock`, `pubspec.lock`, `package-lock.json`) — they must be committed.
