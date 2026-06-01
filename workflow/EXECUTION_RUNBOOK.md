# Phase C — Parallel Execution Runbook (days 3–10)

## Tracks (run in parallel)
- Infra/Backend track, Mobile track, Admin track. EPIC-00 must finish first (everything depends on it).

## Routing
Use the winner table in `docs/superpowers/benchmark/RESULTS.md`. Assign best platform per track;
2 devs each babysit 1–2 tracks.

## Loop (per dev, per track)
1. `python workflow/dispatcher.py` → list ready tasks for your track's layer.
2. For each ready task: create a git worktree, launch the role agent via the platform adapter.
3. Agent runs CORE finish protocol; QA agent gates before `status: done`.
4. Merge the worktree; re-run dispatcher; repeat.

## Gates
- MVP gate = EPIC-16 done. Then pull P1 (EPIC-17–23) as time allows.
- Epic closes only when every assigned design-map screen has a `done` task (existing coverage gate).

## Cost control
- Cheap model: qa, infra, mechanical, scaffolding. Strong model: architecture/ambiguous tasks.
- One task = one small context (task + deps + screen only).

## Failure handling
- qa-fail → status back to in-progress, blocker in BOARD.md, re-dispatch (optionally stronger model/platform).
- Stall/timeout → reassign task to next-ranked platform.
