---
id: T-011
epic: EPIC-00
title: Makefile (dev + tracker commands)
layer: infra
size: S
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

# T-011 · Makefile (dev + tracker commands)

## 1. Feature goal
Provide one Makefile at repo root with every common command, so humans and agents run the same verbs across all three apps and the epic tracker.

## 2. Business logic
Thin wrappers over docker-compose, per-app tooling, and the tracker scripts (T-012). Commands must work from repo root regardless of which app they target.

## 3. What this task DOES
- `Makefile` with targets:
  - **Stack:** `up`, `down`, `logs`, `ps`, `restart`
  - **DB:** `migrate`, `makemigrations`, `superuser`, `dbshell`
  - **Backend:** `api-shell`, `api-test`, `api-lint`
  - **Mobile:** `mobile-run`, `mobile-test`, `mobile-lint`
  - **Admin:** `admin-dev`, `admin-build`, `admin-test`, `admin-lint`
  - **Aggregate:** `test` (all apps), `lint` (all apps)
  - **Tracker:** `status`, `next` (supports `make next LAYER=backend|mobile|admin|infra`), `review-queue`, `epic-report` (call T-012 scripts)
  - **Help:** `help` (default) lists targets with descriptions
- `.PHONY` declarations; `help` as default goal.

## 4. What this task does NOT do
- Does not implement the tracker logic (that's T-012 scripts; this just calls them).

## 5. Files & changes
### Add
- `Makefile`
### Update
- none
### Delete
- none

## 6. Database changes
No DB changes (migrate target wraps Django).

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] All targets present + working
- [ ] `make` / `make help` lists targets
- [ ] `make up` / `make down` control the stack
- [ ] `make test` runs all three app test suites
- [ ] `make lint` runs all three linters
- [ ] tracker targets call T-012 scripts (graceful if scripts absent yet)

## 12. Test plan
### Manual QA
1. `make help` lists everything.
2. `make up` then `make test` runs (backend at least; mobile/admin if tooling present).

## 13. Acceptance criteria
- [ ] Single Makefile drives stack + per-app + aggregate + tracker commands.
- [ ] `make help` is the default and documents each target.

## 14. Self-review
- [ ] Works from repo root
- [ ] No duplicated logic that belongs in scripts
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Backend commands run inside the api container (`docker compose exec api ...`) or via `uv run` — pick one and be consistent; document in `help`.
- If T-012 scripts aren't merged yet, the tracker targets should print a friendly "tracker scripts not installed" rather than failing the whole Makefile.
