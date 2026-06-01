# Contributing to Khatir

Khatir is built by a mix of humans and AI coding agents (Claude Code, Codex, others) working
through a shared, CLI-agnostic task system. The rules below keep everyone — human or agent —
working the same way. Read [`README.md`](README.md) for setup first.

---

## 1. One-time setup

```bash
cp .env.example .env          # local defaults work as-is
make install                  # deps for all three apps (or per-app: api/mobile/admin-install)
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

`make up` then brings the stack up. See the README quickstart.

---

## 2. Branch naming

One branch per task, named after the task it implements:

```
epic-NN/T-XXX-short-slug      e.g.  epic-04/T-007-tenant-list-screen
```

- **Same task = same branch.** If you pick up a partially-done task from another agent,
  continue on its existing branch — never fork a second branch for the same `T-XXX`.
- Don't commit directly to `main`. All work lands via PR.

---

## 3. Commit conventions

Commits follow **[Conventional Commits](https://www.conventionalcommits.org/)** plus an epic
tag. This is enforced by the `commit-msg` pre-commit hook
(`infra/scripts/check_commit_msg.py`):

```
<type>(<optional-scope>): <subject>

[EPIC-NN T-XXX]
```

- **Types:** `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`, `ci`, `style`.
- **The `[EPIC-NN T-XXX]` tag is required** for `feat`, `fix`, `refactor`, `perf`, and `test`
  commits (anywhere in the message). `docs` and `chore` are exempt.
- Subject: imperative mood, lower-case, no trailing period.

Examples:

```
feat(api): add tenant DMP form serializer

[EPIC-05 T-003]
```
```
docs: flesh out root README and add CONTRIBUTING
```

> The task ID is recoverable from git history because every feature branch is
> `epic-NN/T-XXX-slug` and feature commits carry the `[EPIC-NN T-XXX]` tag.

---

## 4. Pre-commit hooks

`pre-commit` runs on changed files on every commit (config: `.pre-commit-config.yaml`):

- **ruff** lint + format — `apps/api`
- **dart format** + **flutter analyze** — `apps/mobile`
- **eslint** + **prettier** — `apps/admin`
- generic hygiene (trailing whitespace, EOF, large files, merge markers)
- secret detection
- the Conventional-Commit + `[EPIC-NN T-XXX]` message check (commit-msg stage)

Run on demand without committing:

```bash
pre-commit run --all-files
```

---

## 5. The task-execution loop

All work is organised as tasks under `documnets/docs/epics/EPIC-NN-*/T-XXX-*.md`. Each task
file is self-contained: it carries everything an agent needs (goal, files to change,
acceptance criteria, self-review checklist). Handoffs happen through the **task file and
git**, never through chat history. The loop:

1. **Pick a task:** `make next` (lowest-ID `todo` task with all `depends_on` met).
   Narrow by lane with `make next LAYER=backend|mobile|admin|infra`.
2. **Start:** set the task frontmatter `status: in-progress`; branch `epic-NN/T-XXX-slug`.
3. **Implement** per the task's §3/§5 and the architecture docs (`documnets/docs/architecture/`).
   Pull every color/spacing/radius/font from `packages/design-tokens` — never hardcode.
   Check off `## 11. Implementation checklist` items as you complete them, annotating each
   with the short commit hash.
4. **Self-review:** run `make test && make lint`; complete the task's `## 14. Self-review`
   checklist and fill in "Files touched (actual)".
5. **Request review:** set `status: review-requested`, append a line to `BOARD.md`, open a PR.
6. **Record decisions:** any non-obvious choice goes in `DECISIONS.md` (one line, dated).

### Definition of Done (gate)

- All `## 13. Acceptance criteria` met.
- All `## 14. Self-review` items checked.
- Tests written/extended and passing; `make lint` clean.

Never set `status: done` if the gate fails — set `status: in-progress` (or `blocked`) and
write the blocker to `BOARD.md`.

---

## 6. Peer review + handoff

The review chain (full detail in
[`documnets/docs/epics/_handoff_protocol.md`](documnets/docs/epics/_handoff_protocol.md)):

```
implement → self-review → review-requested
   → peer review (a DIFFERENT agent than the implementer)
      → done  OR  changes-requested
         → human sign-off → verified
```

- **Implementer ≠ peer reviewer.** Cross-agent review catches single-model blind spots.
- **Blocked?** Set `status: blocked`, fill the task's `## 16. Handoff` (what was tried, why
  blocked, what's needed to unblock, suggested next), note it in `BOARD.md`, and commit so the
  next agent can see it. Always leave the repo green or clearly red.
- **Closing an epic:** all tasks `verified` → `make epic-report EPIC=NN` → human sign-off.

---

## 7. PR / CI gate

Every PR runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml): lint + type-check +
test for each of the three apps. **A PR cannot merge until CI is green.** Run `make test &&
make lint` locally before opening the PR to avoid round-trips.

---

## 8. Coordination channels

Agents never talk to each other directly. Coordinate only through:

- task frontmatter `status`,
- `BOARD.md` (one line per status change),
- tagged git commits.

That's it — keep it boring, keep it legible to a stranger.
