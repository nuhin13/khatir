# Benchmark Kickoff — EPIC-00 + EPIC-01 on 4 platforms

Goal: build the SAME 28 tasks (EPIC-00 scaffold = 16, EPIC-01 auth = 12) on
Claude Code / Codex / Gemini / Cursor, capture metrics, rank with the blind
judge. Each platform builds in its OWN isolated workspace so they never collide.

The agent contract is identical for every platform — they all auto-load the
generated entrypoint (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursor/rules/workflow.md`),
which is the same `workflow/CORE.md`. Only the launch command differs.

---

## 0. One-time setup — isolated workspace per platform

Run each platform against its own clone so commits/files stay separate and
comparable. From the repo root:

```bash
REPO="$(pwd)"
BASE="$HOME/khatir-bench"
mkdir -p "$BASE"
for p in claude codex gemini cursor; do
  rm -rf "$BASE/$p"
  git clone -q "$REPO" "$BASE/$p"
  ( cd "$BASE/$p" && git checkout -q -b "bench/$p" )
done
echo "workspaces ready under $BASE"
```

Each `$BASE/<platform>` is a full clone on branch `bench/<platform>`. The agent
builds there; you diff/score afterward.

---

## 1. The task order (same for all platforms)

Build EPIC-00 then EPIC-01, in dependency order. The dispatcher prints the
currently-ready tasks; re-run it after each task is marked `done`:

```bash
python3 workflow/dispatcher.py --epics EPIC-00,EPIC-01
```

Start: only `EPIC-00/T-001` is ready (scaffold, no deps). As tasks complete and
their frontmatter flips to `status: done`, more unlock. Dependency order:

```
EPIC-00: T-001 → T-002 → T-003 → {T-004, T-007, T-010, T-012} → ...
         T-004 → {T-005, T-006};  T-010 → {T-008, T-009};
         {T-004,T-007,T-009} → {T-011, T-013, T-014, T-015};
         all → T-016 (epic docs)
EPIC-01: needs EPIC-00/T-005 (settings/env) + EPIC-00/T-008 (mobile shell)
         T-001,T-002 → T-003 → T-004 → T-005 → {T-006, T-007}
         T-008 → T-009 → T-010 → T-011 → T-012
```

---

## 2. Launch commands per platform

Each agent is told: act as the role the task's `layer` implies, obey the
entrypoint contract, build one ready task, mark it done, commit `T-YYY: ...`,
then stop. Repeat per task (or let the platform loop if it supports it).

Role mapping by task `layer`: infra/packages/docs/cross-cutting → `infra`,
backend → `backend`, mobile → `mobile`, admin → `admin`.

### Claude Code
```bash
cd "$HOME/khatir-bench/claude"
# one task:
claude -p "Act as the <role> agent per workflow/roles/<role>.md and obey CLAUDE.md. \
Build exactly <task-key> (e.g. EPIC-00/T-001). Run its tests, mark status: done, commit 'T-001: ...'. Then stop."
# To drive the whole benchmark, loop: run dispatcher, take the top ready task, launch, repeat.
```

### Codex CLI
```bash
cd "$HOME/khatir-bench/codex"
codex exec "Act as the <role> agent per workflow/roles/<role>.md and obey AGENTS.md. \
Build exactly <task-key>. Run its tests, mark status: done, commit 'T-001: ...'. Then stop."
```

### Gemini CLI
```bash
cd "$HOME/khatir-bench/gemini"
gemini -p "Act as the <role> agent per workflow/roles/<role>.md and obey GEMINI.md. \
Build exactly <task-key>. Run its tests, mark status: done, commit 'T-001: ...'. Then stop."
```

### Cursor
```bash
cd "$HOME/khatir-bench/cursor"
# Open the folder in Cursor, start a background agent with this prompt:
#   "Act as the <role> agent per workflow/roles/<role>.md and obey .cursor/rules/workflow.md.
#    Build exactly <task-key>. Run its tests, mark status: done, commit 'T-001: ...'. Then stop."
```

---

## 3. Capture metrics per platform

While/after each platform runs, copy `RUN_TEMPLATE.md` to
`docs/superpowers/benchmark/runs/<platform>-EPIC-00-01.md` and fill it:
wall-clock, token/$ cost (from each CLI's usage output), tasks completed,
tests written/passing, reverts/re-runs, scope drift, mistakes.

Quick objective counters per workspace:
```bash
W="$HOME/khatir-bench/<platform>"
( cd "$W" && git log --oneline | grep -cE '^[0-9a-f]+ T-[0-9]+:' )   # tasks committed
( cd "$W" && python3 -m pytest -q 2>&1 | tail -1 )                    # test result
( cd "$W" && git log --oneline | wc -l )                              # total commits (rework proxy)
```

---

## 4. Score — blind judge

1. Anonymize the 4 run records + 4 workspaces as A/B/C/D (keep a private mapping).
2. Hand them + `RUBRIC.md` to the judge prompt in `JUDGE.md` (run it as a fresh
   Claude agent that does NOT know which is which).
3. Record the judge's table + weighted totals in `RESULTS.md`.
4. Human spot-check the top 2 (read the actual code: conventions, tokens not
   hardcoded, structure). Confirm or override the ranking.

---

## 5. Output → Phase C

`RESULTS.md` routing table picks the platform per track (backend/mobile/admin/
infra). That feeds `workflow/EXECUTION_RUNBOOK.md` for the 10-day parallel build.
```
