# Platform-Agnostic Agentic Dev Workflow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable, platform-agnostic agentic workflow + a platform benchmark harness so a 2-dev team can ship the 27-epic Khatir project in 10 days across Claude Code / Codex / Gemini / Cursor.

**Architecture:** Opt 1 backbone (file-based async coordination, git + `BOARD.md` as the message bus, a deterministic Python dispatcher) plus Opt 2 (each platform's native orchestration used *inside* a track). Generic core is plain markdown any CLI auto-loads; thin per-platform adapters describe launch/parallelism/commit. Agents never live-chat — they coordinate through task frontmatter, `BOARD.md`, and tagged commits.

**Tech Stack:** Python 3.13 + pytest (dispatcher + generator, matches the Django backend stack), PyYAML for frontmatter, plain Markdown for all agent-facing contracts/prompts. Git as shared state.

**Folder layout produced by this plan:**
- `workflow/` — the agnostic workflow (core contract, generator, dispatcher, roles, adapters)
- `docs/superpowers/benchmark/` — rubric, run-record template, results
- `docs/superpowers/plans/` — this plan

**Reference inputs (read-only):**
- Spec: `docs/superpowers/specs/2026-06-01-agnostic-agentic-dev-workflow-design.md`
- Existing epics/tasks: `documnets/docs/epics/EPIC-*/T-*.md` (frontmatter `id`, `status`, `depends_on`, `blocks`, `epic`, `layer`)
- Design map: `documnets/docs/architecture/07_design_map.md`
- Handoff protocol: `documnets/docs/epics/_handoff_protocol.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `workflow/CORE.md` | Single source of the generic task-execution contract |
| `workflow/gen_entrypoints.py` | Generate `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/workflow.md` from `CORE.md` |
| `workflow/dispatcher.py` | Parse task frontmatter graph, select ready tasks, print assignments |
| `workflow/board_schema.md` | `BOARD.md` format + status lifecycle |
| `workflow/roles/*.md` | Stateless role-agent prompt templates (backend, mobile, admin, infra, qa) |
| `workflow/adapters/*.md` | Per-platform launch/parallelism/commit adapters |
| `tests/workflow/test_dispatcher.py` | Dispatcher unit tests |
| `tests/workflow/test_gen_entrypoints.py` | Generator unit tests |
| `docs/superpowers/benchmark/RUBRIC.md` | Scoring rubric + weights |
| `docs/superpowers/benchmark/RUN_TEMPLATE.md` | Per-run record template |
| `docs/superpowers/benchmark/JUDGE.md` | Blind judge-agent prompt |
| `docs/superpowers/benchmark/RESULTS.md` | Ranking output template |
| `workflow/EXECUTION_RUNBOOK.md` | Phase C parallel-execution runbook |

---

## Task 1: Workflow skeleton + generic core contract

**Files:**
- Create: `workflow/CORE.md`

- [ ] **Step 1: Write `workflow/CORE.md`**

```markdown
# Khatir Agent Core Contract (platform-agnostic)

You are a role agent (backend | mobile | admin | infra | qa) executing exactly ONE task.

## Load only what you need
1. Read the assigned task file `documnets/docs/epics/EPIC-XX/T-YYY-*.md` — all sections.
2. Read each task listed in its `depends_on` frontmatter (their committed outputs only).
3. If the task names a screen, open `documnets/docs/architecture/07_design_map.md`,
   find the screen key, then its `reg('<key>')` block in `documnets/docs/design/khatir-ui/proto/*.js`.
Do NOT read the whole repo. Small context = correct + cheap.

## Build rules
- Follow `documnets/docs/architecture/01..06` and `enums.md`.
- Pull every color/spacing/radius/font from `packages/design-tokens`. Never hardcode prototype hex/px.
- Match prototype layout/composition; values come from tokens.
- Latest stable library versions; no beta/RC.

## Definition of Done (gate)
- Task §acceptance criteria all met.
- Task §self-review checklist all checked.
- Tests written/extended and passing.

## Finish protocol
1. Set `status: done` in the task frontmatter.
2. Append a line to `BOARD.md` (see `workflow/board_schema.md`).
3. Commit: `T-YYY: <imperative summary>`.
Never set `status: done` if the DoD gate fails — set `status: in-progress` and write the blocker to `BOARD.md`.

## Communication
You never talk to other agents directly. Coordinate only through:
task frontmatter `status`, `BOARD.md`, and tagged git commits.
```

- [ ] **Step 2: Commit**

```bash
git add workflow/CORE.md
git commit -m "workflow: add generic agent core contract"
```

---

## Task 2: Entrypoint generator (TDD)

Generates platform entrypoints from the single source so all CLIs load identical guidance.

**Files:**
- Create: `workflow/gen_entrypoints.py`
- Test: `tests/workflow/test_gen_entrypoints.py`

- [ ] **Step 1: Write the failing test**

```python
# tests/workflow/test_gen_entrypoints.py
from pathlib import Path
from workflow.gen_entrypoints import generate

def test_generate_writes_all_entrypoints(tmp_path):
    core = tmp_path / "CORE.md"
    core.write_text("# Core\nrules here\n", encoding="utf-8")
    written = generate(core, tmp_path)
    names = {p.name for p in written}
    assert names == {"CLAUDE.md", "AGENTS.md", "GEMINI.md", "workflow.md"}
    body = (tmp_path / "CLAUDE.md").read_text(encoding="utf-8")
    assert "rules here" in body
    assert "GENERATED FROM workflow/CORE.md" in body
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tests/workflow/test_gen_entrypoints.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'workflow.gen_entrypoints'`

- [ ] **Step 3: Write minimal implementation**

```python
# workflow/gen_entrypoints.py
"""Generate per-platform entrypoints from workflow/CORE.md."""
from pathlib import Path

BANNER = "<!-- GENERATED FROM workflow/CORE.md — edit CORE.md, then regenerate. -->\n\n"

# filename -> output directory relative to repo root
TARGETS = {
    "CLAUDE.md": ".",
    "AGENTS.md": ".",
    "GEMINI.md": ".",
    "workflow.md": ".cursor/rules",
}

def generate(core_path: Path, repo_root: Path) -> list[Path]:
    core = core_path.read_text(encoding="utf-8")
    written: list[Path] = []
    for name, subdir in TARGETS.items():
        out_dir = repo_root / subdir
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / name
        out.write_text(BANNER + core, encoding="utf-8")
        written.append(out)
    return written

if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    for p in generate(root / "workflow" / "CORE.md", root):
        print(f"wrote {p}")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tests/workflow/test_gen_entrypoints.py -v`
Expected: PASS

- [ ] **Step 5: Generate the real entrypoints**

Run: `python workflow/gen_entrypoints.py`
Expected: prints `wrote ./CLAUDE.md`, `wrote ./AGENTS.md`, `wrote ./GEMINI.md`, `wrote .cursor/rules/workflow.md`

- [ ] **Step 6: Commit**

```bash
git add workflow/gen_entrypoints.py tests/workflow/test_gen_entrypoints.py CLAUDE.md AGENTS.md GEMINI.md .cursor/rules/workflow.md
git commit -m "workflow: add entrypoint generator and generate platform files"
```

---

## Task 3: BOARD schema

**Files:**
- Create: `workflow/board_schema.md`
- Create: `BOARD.md`

- [ ] **Step 1: Write `workflow/board_schema.md`**

```markdown
# BOARD.md schema (async message bus)

One line per event, newest at bottom. Format:

`<UTC-timestamp> | <task-id> | <role> | <platform> | <status> | <note>`

- status ∈ {claimed, in-progress, blocked, done, qa-fail}
- note: short reason for blocked/qa-fail, else "-"

Status lifecycle: todo → claimed → in-progress → (qa-fail → in-progress)* → done.
The dispatcher reads task frontmatter `status` as truth; BOARD.md is the human-readable trail.
```

- [ ] **Step 2: Create empty board**

```markdown
# BOARD

<!-- timestamp | task-id | role | platform | status | note -->
```

- [ ] **Step 3: Commit**

```bash
git add workflow/board_schema.md BOARD.md
git commit -m "workflow: add BOARD schema and empty board"
```

---

## Task 4: Dispatcher — ready-task selection (TDD)

Parses every `T-*.md` frontmatter, builds the dependency graph, returns tasks whose deps are all `done` and that are not themselves done/in-progress.

**Files:**
- Create: `workflow/dispatcher.py`
- Test: `tests/workflow/test_dispatcher.py`

- [ ] **Step 1: Write the failing test**

```python
# tests/workflow/test_dispatcher.py
from pathlib import Path
from workflow.dispatcher import parse_task, ready_tasks

TASK_A = """---
id: T-001
epic: EPIC-00
layer: infra
status: done
depends_on: []
---
body
"""

TASK_B = """---
id: T-002
epic: EPIC-00
layer: backend
status: todo
depends_on: [T-001]
---
body
"""

TASK_C = """---
id: T-003
epic: EPIC-00
layer: mobile
status: todo
depends_on: [T-002]
---
body
"""

def _write(tmp_path, name, text):
    p = tmp_path / name
    p.write_text(text, encoding="utf-8")
    return p

def test_parse_task_reads_frontmatter(tmp_path):
    p = _write(tmp_path, "T-001.md", TASK_A)
    t = parse_task(p)
    assert t.id == "T-001"
    assert t.status == "done"
    assert t.depends_on == []

def test_ready_tasks_only_returns_unblocked_todo(tmp_path):
    _write(tmp_path, "T-001.md", TASK_A)
    _write(tmp_path, "T-002.md", TASK_B)
    _write(tmp_path, "T-003.md", TASK_C)
    ready = [t.id for t in ready_tasks(tmp_path)]
    assert ready == ["T-002"]  # T-001 done, T-003 blocked by T-002
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tests/workflow/test_dispatcher.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'workflow.dispatcher'`

- [ ] **Step 3: Write minimal implementation**

```python
# workflow/dispatcher.py
"""Read task frontmatter, build the dependency graph, list ready tasks."""
from __future__ import annotations
from dataclasses import dataclass, field
from pathlib import Path
import yaml

@dataclass
class Task:
    id: str
    epic: str
    layer: str
    status: str
    depends_on: list[str] = field(default_factory=list)
    path: Path | None = None

def parse_task(path: Path) -> Task:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise ValueError(f"{path}: no frontmatter")
    _, fm, _ = text.split("---", 2)
    data = yaml.safe_load(fm) or {}
    return Task(
        id=str(data["id"]),
        epic=str(data.get("epic", "")),
        layer=str(data.get("layer", "")),
        status=str(data.get("status", "todo")),
        depends_on=[str(d) for d in (data.get("depends_on") or [])],
        path=path,
    )

def load_tasks(root: Path) -> dict[str, Task]:
    tasks: dict[str, Task] = {}
    for p in sorted(root.rglob("T-*.md")):
        try:
            t = parse_task(p)
        except (ValueError, KeyError):
            continue
        tasks[t.id] = t
    return tasks

def ready_tasks(root: Path) -> list[Task]:
    tasks = load_tasks(root)
    done = {tid for tid, t in tasks.items() if t.status == "done"}
    out = []
    for t in tasks.values():
        if t.status != "todo":
            continue
        if all(dep in done for dep in t.depends_on):
            out.append(t)
    return sorted(out, key=lambda t: t.id)

if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent / "documnets" / "docs" / "epics"
    for t in ready_tasks(root):
        print(f"{t.id}\t{t.epic}\t{t.layer}")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tests/workflow/test_dispatcher.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Dry-run against the real epics**

Run: `python workflow/dispatcher.py`
Expected: prints the currently-ready task IDs (tasks whose deps are all `done`). With all tasks `todo`, only dependency-free tasks (e.g. EPIC-00 T-001) appear. If output is empty, confirm task frontmatter uses `status:` and `depends_on:` as in the schema.

- [ ] **Step 6: Commit**

```bash
git add workflow/dispatcher.py tests/workflow/test_dispatcher.py
git commit -m "workflow: add dependency-aware task dispatcher"
```

---

## Task 5: Role-agent prompt templates

Five stateless templates. Each wraps `CORE.md` with role-specific scope.

**Files:**
- Create: `workflow/roles/backend.md`
- Create: `workflow/roles/mobile.md`
- Create: `workflow/roles/admin.md`
- Create: `workflow/roles/infra.md`
- Create: `workflow/roles/qa.md`

- [ ] **Step 1: Write `workflow/roles/backend.md`**

```markdown
# Role: Backend Agent
Read and obey `workflow/CORE.md` first. Then:
- Scope: Django 6 + DRF, PostgreSQL 17, Redis 8, Celery, FastAPI ai-gateway.
- Output: models, serializers, views, urls, migrations, Celery tasks, pytest tests.
- Follow `architecture/04_coding_conventions.md` (API envelope, error handling) and `enums.md`.
- Never touch mobile/admin files. If a task needs them, stop and note in BOARD.md.
```

- [ ] **Step 2: Write `workflow/roles/mobile.md`**

```markdown
# Role: Mobile Agent
Read and obey `workflow/CORE.md` first. Then:
- Scope: Flutter 3.44, Riverpod, Freezed, go_router, dio, fl_chart, intl (bn/en).
- Output: screens/widgets matching the assigned design-map screen, data layer, widget tests.
- Pull all visual values from `packages/design-tokens`. Match prototype layout exactly.
- Three role shells exist (Landlord/Manager/Tenant) — build only the one the task names.
```

- [ ] **Step 3: Write `workflow/roles/admin.md`**

```markdown
# Role: Admin Agent
Read and obey `workflow/CORE.md` first. Then:
- Scope: Next.js 16, React 19, TS strict, TailwindCSS, @tanstack/react-query, zod.
- Output: pages/components matching the assigned design-map screen, query hooks, tests.
- Pull all visual values from `packages/design-tokens`. Enforce role-based access + audit plumbing.
```

- [ ] **Step 4: Write `workflow/roles/infra.md`**

```markdown
# Role: Infra Agent
Read and obey `workflow/CORE.md` first. Then:
- Scope: mono-repo structure, Docker/Compose, CI/CD (GitHub Actions), Makefile, design-tokens package.
- Output: config, compose files, pipelines, scaffolding. Keep secrets in env per `03_env_and_config.md`.
```

- [ ] **Step 5: Write `workflow/roles/qa.md`**

```markdown
# Role: QA Agent (gate)
Read and obey `workflow/CORE.md` first. Then for the task under review:
- Run the task's tests. Check every §acceptance criterion and §self-review item.
- If the task is a UI task, confirm the assigned design-map screen is implemented and tokens (not hardcoded values) are used.
- Verdict: PASS → allow `status: done`. FAIL → set `status: in-progress`, write the failing criterion to BOARD.md.
- You do not fix code. You judge and report only.
```

- [ ] **Step 6: Commit**

```bash
git add workflow/roles/
git commit -m "workflow: add role-agent prompt templates"
```

---

## Task 6: Platform adapters

One thin adapter per platform: launch, parallelism, commit.

**Files:**
- Create: `workflow/adapters/claude.md`
- Create: `workflow/adapters/codex.md`
- Create: `workflow/adapters/gemini.md`
- Create: `workflow/adapters/cursor.md`

- [ ] **Step 1: Write `workflow/adapters/claude.md`**

```markdown
# Adapter: Claude Code
- Entrypoint: auto-loads `CLAUDE.md`.
- Launch one task: `claude -p "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: spawn role sub-agents via the Agent tool; isolate parallel writers with git worktrees.
- Cost: use a cheap model for qa/infra/mechanical tasks, the strongest model for architecture tasks.
- Commit: agent commits with `T-YYY:` prefix per CORE finish protocol.
```

- [ ] **Step 2: Write `workflow/adapters/codex.md`**

```markdown
# Adapter: Codex CLI
- Entrypoint: auto-loads `AGENTS.md`.
- Launch one task: `codex exec "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: one process per task, each in its own git worktree.
- Cost: pick the reasoning effort/model per task weight.
- Commit: `T-YYY:` prefix.
```

- [ ] **Step 3: Write `workflow/adapters/gemini.md`**

```markdown
# Adapter: Gemini CLI
- Entrypoint: auto-loads `GEMINI.md`.
- Launch one task: `gemini -p "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: one process per task, each in its own git worktree.
- Cost: select model tier per task weight.
- Commit: `T-YYY:` prefix.
```

- [ ] **Step 4: Write `workflow/adapters/cursor.md`**

```markdown
# Adapter: Cursor
- Entrypoint: auto-loads `.cursor/rules/workflow.md` (also reads `AGENTS.md`).
- Launch one task: background agent on the task, role prompt = `workflow/roles/<role>.md`.
- Parallelism: multiple background agents, isolate writers with worktrees.
- Commit: `T-YYY:` prefix.
```

- [ ] **Step 5: Commit**

```bash
git add workflow/adapters/
git commit -m "workflow: add per-platform adapters"
```

---

## Task 7: Benchmark rubric

**Files:**
- Create: `docs/superpowers/benchmark/RUBRIC.md`

- [ ] **Step 1: Write the rubric**

```markdown
# Platform Benchmark Rubric

Bake-off epics (same on all 4 platforms): EPIC-00 (scaffold) + EPIC-01 (auth, full-stack).

Score each metric 0–10; weighted total = ranking.

| Metric | Weight | How to score |
|--------|--------|--------------|
| Feature completion % | 0.25 | tasks fully meeting acceptance / total |
| Tests pass ratio | 0.15 | passing / written; 0 if none written |
| Rework / mistake ratio | 0.15 | inverse of (re-runs + reverted commits) |
| Plan adherence | 0.15 | asked-vs-done; penalize scope drift + skipped steps |
| Token + $ cost | 0.15 | normalized inverse cost across the 4 runs |
| Wall-clock | 0.05 | normalized inverse time |
| Code quality | 0.07 | reviewer score: conventions, tokens-not-hardcoded, structure |
| Self-recovery | 0.03 | handled its own errors without human help? |

Weighted total per platform → rank 1..4. Human spot-checks top 2.
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/benchmark/RUBRIC.md
git commit -m "benchmark: add scoring rubric"
```

---

## Task 8: Benchmark run-record template

**Files:**
- Create: `docs/superpowers/benchmark/RUN_TEMPLATE.md`

- [ ] **Step 1: Write the template**

```markdown
# Benchmark Run — <platform> — <epic-id>

- Date / operator:
- Command used:
- Model / tier:
- Wall-clock:
- Token usage (in/out) + est. $:

## What was asked vs what was done
- Asked:
- Done:
- Scope drift / skipped:

## Tasks
| Task | Acceptance met? | Tests written | Tests pass | Reverts/re-runs |
|------|-----------------|---------------|------------|-----------------|

## Mistakes / retro
-

## Raw scores (fill against RUBRIC.md)
| Metric | Raw 0–10 |
|--------|----------|
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/benchmark/RUN_TEMPLATE.md
git commit -m "benchmark: add per-run record template"
```

---

## Task 9: Judge prompt + results template

**Files:**
- Create: `docs/superpowers/benchmark/JUDGE.md`
- Create: `docs/superpowers/benchmark/RESULTS.md`

- [ ] **Step 1: Write `docs/superpowers/benchmark/JUDGE.md`**

```markdown
# Blind Judge Agent

Inputs: the 4 run records + the 4 produced codebases (anonymized as A/B/C/D), `RUBRIC.md`.
Do NOT know which platform is which.

For each anonymized run:
1. Score every rubric metric 0–10 with a one-line justification.
2. Compute the weighted total.
Then output a ranking table A–D and the single highest-confidence winner, plus the top weakness of each.
Output only the table + justifications. No praise, no filler.
```

- [ ] **Step 2: Write `docs/superpowers/benchmark/RESULTS.md`**

```markdown
# Benchmark Results

| Rank | Platform | Weighted total | Top strength | Top weakness |
|------|----------|----------------|--------------|--------------|

## Routing decision (fills the Phase C table)
- Backend track →
- Mobile track →
- Admin track →
- Infra track →
- QA →

## Human spot-check notes (top 2)
-
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/benchmark/JUDGE.md docs/superpowers/benchmark/RESULTS.md
git commit -m "benchmark: add judge prompt and results template"
```

---

## Task 10: Phase C execution runbook

**Files:**
- Create: `workflow/EXECUTION_RUNBOOK.md`

- [ ] **Step 1: Write the runbook**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add workflow/EXECUTION_RUNBOOK.md
git commit -m "workflow: add Phase C execution runbook"
```

---

## Final: publish to main

- [ ] **Step 1: Run the full test suite**

Run: `python -m pytest tests/workflow/ -v`
Expected: all dispatcher + generator tests PASS.

- [ ] **Step 2: Merge to main and push**

```bash
git checkout main
git merge --no-ff agentic-workflow-design -m "Add platform-agnostic agentic dev workflow + benchmark harness"
git push origin main
```
Expected: push succeeds. If no remote is configured, report it instead of failing silently.

---

## Self-Review

- **Spec coverage:** Layer 1 → Task 1; Layer 2 (adapters) → Task 6; Layer 3 (dispatcher + roles + board) → Tasks 3,4,5; cost optimization → Tasks 5,10; Phase A (rubric/harness/judge/results) → Tasks 7,8,9; Phase C → Task 10; entrypoint generation → Task 2. All spec sections covered.
- **Placeholder scan:** templates (`RUN_TEMPLATE.md`, `RESULTS.md`) intentionally contain blank fields to fill at runtime — these are deliverable forms, not plan placeholders. No "TBD/implement later" in any code step.
- **Type consistency:** `Task` dataclass fields (`id`, `epic`, `layer`, `status`, `depends_on`, `path`) used consistently across `parse_task`, `load_tasks`, `ready_tasks`, and tests. `generate(core_path, repo_root)` signature matches its test.
