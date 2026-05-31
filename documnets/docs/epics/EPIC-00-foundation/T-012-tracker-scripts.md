---
id: T-012
epic: EPIC-00
title: Tracker scripts (status/next/review-queue/epic-report)
layer: infra
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
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

# T-012 · Tracker scripts (status/next/review-queue/epic-report)

## 1. Feature goal
Build the small Python scripts that parse task-file YAML frontmatter across `docs/epics/**` and power the autonomous loop: report overall status, find the next executable task, list the review queue, and generate an epic completion report.

## 2. Business logic
This is the engine behind the execution model in `_task_template.md` and `_handoff_protocol.md`. A task is "executable next" when its `status: todo` and all `depends_on` are `done` or `verified`. Scripts read frontmatter only — they never need the task body.

## 3. What this task DOES
- `infra/scripts/tracker.py` (single module) with subcommands:
  - `status` — counts by status across all epics + per-epic progress table; also refreshes `docs/epics/README.md` board and each `_checklist.md`.
  - `next` — prints the lowest-ID `todo` task whose `depends_on` are all satisfied (respects cross-epic `EPIC-NN.T-XXX` refs). Supports `--layer <backend|mobile|admin|infra|docs|cross-cutting>` to return the next ready task in one lane only (enables parallel per-lane agent streams).
  - `review-queue` — lists tasks with `status: review-requested`.
  - `epic-report NN` — generates a completion report for EPIC-NN from its task frontmatter (used when all tasks are done/verified).
  - `screen-coverage` — cross-checks the Screen Coverage Ledger in `docs/architecture/07_design_map.md` against existing task files: flags any of the 44 prototype screens whose owning task is missing, still `_TBD_`, or not yet `done`/`verified`. Prevents a screen being silently dropped.
- Frontmatter parser (PyYAML) tolerant of missing optional fields.
- Unit tests with a temp fixture epic.

## 4. What this task does NOT do
- Does not run agents or execute tasks. It only reports/selects.
- Does not modify task files except optionally stamping the README/checklist boards on `status`.

## 5. Files & changes
### Add
- `infra/scripts/tracker.py`
- `infra/scripts/requirements.txt` (PyYAML) or add to api deps
- `infra/scripts/tests/test_tracker.py` + fixture epic
### Update
- remove `infra/scripts/.gitkeep`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes (CLI output).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] Frontmatter parser (PyYAML)
- [ ] `status` aggregates + rewrites README board + per-epic checklist
- [ ] `next` respects depends_on incl. cross-epic refs
- [ ] `next --layer <lane>` filters to one lane (backend/mobile/admin/infra/docs/cross-cutting)
- [ ] `review-queue` lists review-requested
- [ ] `epic-report NN` generates a report
- [ ] `screen-coverage` checks all 44 ledger screens have a done/verified task; flags gaps
- [ ] tests with a temp fixture epic pass
- [ ] callable as `python infra/scripts/tracker.py <cmd>`

## 12. Test plan
### Automated
- test_next → with a fixture where T-001 done + T-002 todo (deps met), `next` returns T-002
- test_next_blocked → unmet dep is skipped
- test_status → counts correct
- test_review_queue → only review-requested listed
### Manual QA
1. `python infra/scripts/tracker.py status` against the real epics prints the board.
2. `... next` returns EPIC-00 T-001 (or the first unmet-dep-free todo).

## 13. Acceptance criteria
- [ ] `make status/next/review-queue/epic-report` (via T-011) produce correct output.
- [ ] `next` correctly enforces dependency satisfaction.

## 14. Self-review
- [ ] Parser tolerant of optional fields
- [ ] Cross-epic dependency refs handled
- [ ] Tests pass
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Dependency satisfied = referenced task's `status` in {done, verified}.
- Cross-epic ref format: `EPIC-NN.T-XXX`; same-epic ref: `T-XXX`.
- Keep output plain-text and greppable; `status` may also emit `--json` for future tooling.
- This script is what makes the build CLI-agnostic — any agent calls `next`, reads the returned task file, executes.
