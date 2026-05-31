---
id: T-016
epic: EPIC-00
title: Root docs wiring (README, CONTRIBUTING, DECISIONS)
layer: docs
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-001, T-003, T-004, T-005, T-006, T-007, T-008, T-009, T-010, T-011, T-012, T-013, T-014, T-015]
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

# T-016 · Root docs wiring (README, CONTRIBUTING, DECISIONS)

## 1. Feature goal
Finalize the repo's human-facing docs so a brand-new contributor (human or agent) can clone, run, and start contributing in minutes, and close out EPIC-00 with its completion report.

## 2. Business logic
This is the capstone of EPIC-00 — it ties together everything the prior tasks built into a coherent onboarding story. It also produces the epic completion report per `_handoff_protocol.md`.

## 3. What this task DOES
- Flesh out root `README.md`: what Khatir is, the mono-repo map, prerequisites, `make up` quickstart for each app, links to `docs/architecture/00_overview.md` and `docs/epics/_master_plan.md`, CI badge.
- `CONTRIBUTING.md`: branch naming, commit format, `pre-commit install`, the task-execution loop (`make next` → implement → self-review → review-requested), how peer review + handoff work (link to `_handoff_protocol.md`).
- Ensure `DECISIONS.md` captures EPIC-00 decisions (uv, latest-stable policy, monorepo, design-tokens approach, eager-celery-in-test, etc.).
- Generate `docs/epics/EPIC-00-foundation/_completion_report.md` once all tasks are done/verified.
- Update `docs/epics/README.md` board (EPIC-00 → done) via `make status`.

## 4. What this task does NOT do
- No code changes; documentation + report only.

## 5. Files & changes
### Add
- `CONTRIBUTING.md`
- `docs/epics/EPIC-00-foundation/_completion_report.md`
### Update
- `README.md` (full version)
- `DECISIONS.md` (EPIC-00 decisions)
- `docs/epics/README.md` (board) + `EPIC-00-foundation/_checklist.md`
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
- [ ] README full: intro, map, prerequisites, quickstart per app, links, CI badge
- [ ] CONTRIBUTING: branch/commit/pre-commit/task-loop/review/handoff
- [ ] DECISIONS captures EPIC-00 choices
- [ ] completion report generated from frontmatter
- [ ] tracker board updated (EPIC-00 done)

## 12. Test plan
### Manual QA
1. Follow README from scratch on a clean checkout → `make up` brings everything up.
2. `make status` shows EPIC-00 complete.

## 13. Acceptance criteria
- [ ] A new contributor can go clone → run in <15 min using only the README.
- [ ] EPIC-00 completion report exists + board shows done.

## 14. Self-review
- [ ] Quickstart actually works on a clean clone
- [ ] All EPIC-00 acceptance criteria (in _epic.md) satisfied
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Before writing the completion report, verify every EPIC-00 task is `done`/`verified` and the epic-level acceptance criteria in `_epic.md` all pass. If any fail, do not close — set this task `blocked` and note what's outstanding.
- The completion report follows the template in `_handoff_protocol.md` §3 Gate 3.
