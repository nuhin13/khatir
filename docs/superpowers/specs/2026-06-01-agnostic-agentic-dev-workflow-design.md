# Design Spec — Platform-Agnostic Agentic Dev Workflow for Khatir

- **Date:** 2026-06-01
- **Status:** Approved (design), pending implementation plan
- **Owner:** 2-dev team + agent fleet
- **Objective:** Ship the 27-epic / 310-task Khatir project in **10 days** using a platform-agnostic agentic workflow, a minimal human team, and the best-performing CLI platform(s) selected by benchmark.

---

## 1. Problem & Goal

A human software team would need >1 month to build Khatir (27 epics, 310 specced tasks across Django backend, Flutter mobile, Next.js admin). Goal: compress to **10 days** with 2 devs by driving the work through coding-agent CLIs.

Constraints:
- **Platform-agnostic core**: the workflow must run on Claude Code, Codex, Gemini, Cursor with only thin per-platform adapters.
- **Heterogeneous agents cannot live-chat reliably** → coordination must be async and durable.
- **Cost-aware**: token/$ optimization is a first-class requirement.
- **Reusable**: the workflow is a team asset, not a one-off script.

Success = (a) a working benchmark + ranking of platforms, (b) a reusable 3-layer agnostic workflow, (c) parallel execution that ships MVP (EPIC-00→16) and ideally P1 within 10 days.

---

## 2. Key Insight

**The repo already IS the agnostic layer.** The epics, the 15-section task template, the design-map (screen→task ledger), and the handoff protocol are plain markdown that any CLI can read. Therefore:

- **Generic skill** = a portable, prose-only *task-execution contract*. No platform API.
- **Platform-specific skill** = a thin adapter describing how to launch, parallelize, spawn sub-agents, and commit on that platform.

This split is the foundation of the whole design.

---

## 3. Architecture Decision

**Chosen: Opt 1 backbone + Opt 2 inside each track.**

- **Opt 1 (backbone):** File-based async coordination. Shared state = repo files + git commits + a single `BOARD.md`. A deterministic dispatcher reads task frontmatter (`status`, `depends_on`, `blocks`) and hands ready tasks to role agents. Durable, cheap, survives all 4 platforms.
- **Opt 2 (inside a track):** Use each platform's *native* orchestration (Claude subagents/Workflow, Cursor background agents, Codex/Gemini exec loops) as an accelerator **within** a single track, not as the cross-platform backbone.
- **Rejected — Opt 3:** Live agent-to-agent protocol (MCP/queue) across heterogeneous CLIs. Fragile, token-heavy, won't fit timeline.

**Agent-to-agent communication = async, file-based only:** task `status` frontmatter + `BOARD.md` + git commit messages (tagged with task ID). No live messaging across platforms.

---

## 4. The Agnostic Workflow — 3 Layers

### Layer 1 — Generic Core (platform-independent)

Single source of truth generates per-platform entrypoints.

- **`workflow/CORE.md`** (source) → generates `CLAUDE.md`, `AGENTS.md` (Codex + Cursor), `GEMINI.md`. Identical content, different filenames so each CLI auto-loads it.
- **Task-execution contract** (the central generic skill). Steps an agent follows for ONE task:
  1. Read the `T-XXX` task file (all 15 sections).
  2. Read its `depends_on` tasks' outputs + the assigned design-map screen (`07_design_map.md` → `proto/*.js` screen key).
  3. Implement per architecture rules (`architecture/01..06`, `enums.md`) — pull values from `packages/design-tokens`, never hardcode prototype hex/px.
  4. Run the task's §self-review checklist.
  5. Run/extend tests; meet the §acceptance criteria (Definition of Done).
  6. Set `status: done` in frontmatter; update `BOARD.md`.
  7. Commit with `T-XXX:` prefix.
- **DoD + acceptance gate**: already encoded per task in the template; the contract enforces it.
- **Handoff protocol**: reuse existing `documnets/docs/epics/_handoff_protocol.md`.

### Layer 2 — Platform Adapter (thin, ~1 page per platform)

For each of Claude / Codex / Gemini / Cursor:
- How to launch an agent on a task.
- Native parallelism mechanism (subagents, background agents, exec loops).
- How to spawn role sub-agents.
- Cost knobs (model selection, context limits).

### Layer 3 — Orchestration

- **TL agent** = planning agent + **dispatcher script** (deterministic). Reads dependency graph, selects ready tasks (all `depends_on` are `done`), assigns to a role + platform per the routing table.
- **Role agents** (stateless): `backend`, `mobile`, `admin`, `infra`, `QA`. Each loads ONLY its task + deps + screen → small context.
- **QA agent** gates every task: runs tests + reviews against acceptance criteria before allowing `status: done`. Failing → status back to `in-progress` with notes in `BOARD.md`.

---

## 5. Cost / Token Optimization

- **Per-task isolation** → tiny context windows (load task+deps+screen, not whole repo).
- **Model tiering**: cheap model for QA/lint/mechanical/scaffolding; expensive model only for architecture/ambiguous tasks.
- **Worktree isolation** for parallel writers → no merge collisions, no shared mutable context.
- **Compressed prompts** for role agents (caveman-style instruction blocks).
- **Cache-friendly**: stable system/core prompt prefix per platform.

---

## 6. Phases (maps to user's 5 steps)

### Phase A — Benchmark & Rank (1–2 days) [steps 1–3]

- **Controlled bake-off**: run the SAME epics on all 4 platforms: **EPIC-00 (scaffold) + EPIC-01 (auth, full-stack)** — covers infra + backend + a bit of client, small enough to finish 4×.
- **Rubric** (per platform run):
  - feature-completion %
  - tests pass (count/ratio)
  - rework / mistake ratio
  - plan-adherence (asked vs done; scope drift)
  - token + $ cost
  - wall-clock time
  - code-quality score (review)
  - self-recovery (handled own errors?)
- **Judging**: **blind neutral judge agent** (run on Claude) scores all 4 outputs against the rubric → ranking table. **+ human spot-check** of the top 2 to confirm.
- **Output**: `docs/superpowers/benchmark/RESULTS.md` with ranking + per-platform retro (what asked vs what done, mistakes, cost).

### Phase B — Build Agnostic Workflow (~day 2–3, overlaps A) [step 5]

- Implement Layers 1–3 above, incorporating benchmark learnings (which platform needs which guardrails).
- Deliverables: `workflow/CORE.md` + generated entrypoints, dispatcher script, role-agent prompt templates, `BOARD.md` schema, platform adapters.

### Phase C — Parallel Execution (days 3–10) [step 4]

- Dependency graph supports parallel tracks: **Mobile ∥ Admin ∥ Backend/Infra**.
- Assign best platform(s) per track from Phase A ranking.
- 2 devs: each babysits 1–2 tracks/platforms; dispatcher feeds ready tasks; QA gate; merge via worktrees.
- Target order: EPIC-00 → MVP (01–16) gate → P1 (17–23) as time allows.

---

## 7. Components & Interfaces

| Component | Purpose | Input | Output |
|-----------|---------|-------|--------|
| `workflow/CORE.md` | Generic contract source | — | generated entrypoints |
| Entrypoint generator | Emit CLAUDE/AGENTS/GEMINI.md from CORE | CORE.md | 3 files |
| Dispatcher script | Pick ready tasks, route to role+platform | task frontmatter graph | assignments |
| Role-agent prompt templates | Stateless task executor per role | task+deps+screen | code + commit + status |
| QA agent | Gate before `done` | task + diff | pass/fail + notes |
| `BOARD.md` | Async status bus | agent updates | human-readable state |
| Benchmark harness | Run epic on a platform, capture metrics | epic + platform | run artifacts |
| Judge agent | Blind score runs | run artifacts + rubric | ranking table |

---

## 8. Error Handling

- Task fails QA → `status: in-progress`, failure notes in `BOARD.md`, re-dispatch (optionally to a stronger model/platform).
- Merge conflict → worktree isolation prevents most; dispatcher serializes tasks that touch shared files (detect via task `layer` + file hints).
- Platform stall/timeout → dispatcher reassigns task to next-ranked platform.
- Cost overrun → model-tier downgrade for mechanical tasks; alert in `BOARD.md`.

---

## 9. Testing

- **Benchmark**: each run's tests must execute; pass-ratio is a rubric metric.
- **Workflow**: dry-run dispatcher on the dependency graph (no real agents) to confirm correct ready-task selection + ordering.
- **Execution**: QA agent runs each task's acceptance tests; epic closes only when every assigned design-map screen has a `done` task (existing coverage gate).

---

## 10. Out of Scope (YAGNI)

- Live cross-platform agent messaging (Opt 3).
- A custom UI/dashboard for orchestration (BOARD.md + git suffice).
- Auto-scaling beyond 4 platforms / 2 devs.
- Benchmarking platforms not owned (OpenCode, Antigravity) — excluded; revisit only if top-2 underperform.

---

## 11. Open Questions

- None blocking. Routing table (which role→which platform) is filled after Phase A produces the ranking.
