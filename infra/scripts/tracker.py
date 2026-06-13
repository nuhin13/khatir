#!/usr/bin/env python3
"""Khatir tracker — parse task-file frontmatter and power the autonomous loop.

Subcommands:
  status          counts by status + per-epic progress table; refreshes the
                  epics/README.md board and each EPIC-NN/_checklist.md.
  next            lowest-ID `todo` task whose `depends_on` are all satisfied
                  (done/verified). `--layer <lane>` narrows to one lane.
  review-queue    lists tasks with `status: review-requested`.
  epic-report NN  completion report for EPIC-NN from its task frontmatter.
  screen-coverage cross-checks the Screen Coverage Ledger in
                  architecture/07_design_map.md against task files.

Frontmatter parsing reuses workflow/dispatcher.py (load_tasks / parse_task)
rather than duplicating it. Reads frontmatter only — never the task body.

Run as: python infra/scripts/tracker.py <cmd>
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

# --- Reuse the dispatcher's parser if available, else fall back locally. -----
REPO_ROOT = Path(__file__).resolve().parents[2]
EPICS_DIR = REPO_ROOT / "documnets" / "docs" / "epics"
DESIGN_MAP = REPO_ROOT / "documnets" / "docs" / "architecture" / "07_design_map.md"

# A dependency is satisfied when the referenced task is in one of these states.
SATISFIED = {"done", "verified"}
VALID_LAYERS = {"backend", "mobile", "admin", "infra", "docs", "cross-cutting"}

sys.path.insert(0, str(REPO_ROOT / "workflow"))
try:
    from dispatcher import Task, load_tasks, parse_task  # type: ignore  # noqa: F401
except Exception:  # pragma: no cover - dispatcher should exist, but stay robust
    @dataclass
    class Task:  # type: ignore[no-redef]
        id: str
        epic: str
        layer: str
        status: str
        depends_on: list[str] = field(default_factory=list)
        path: Path | None = None

        @property
        def key(self) -> str:
            return f"{self.epic}/{self.id}"

        def dep_keys(self) -> list[str]:
            out = []
            for dep in self.depends_on:
                out.append(dep if "/" in dep else f"{self.epic}/{dep}")
            return out

    def parse_task(path: Path) -> Task:  # type: ignore[no-redef]
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

    def load_tasks(root: Path) -> dict[str, Task]:  # type: ignore[no-redef]
        tasks: dict[str, Task] = {}
        for p in sorted(root.rglob("T-*.md")):
            try:
                t = parse_task(p)
            except (ValueError, KeyError, yaml.YAMLError):
                continue
            tasks[t.key] = t
        return tasks


# --- Extra frontmatter helpers (title etc. — not on the dispatcher Task). ----
def task_field(path: Path, key: str, default: str = "") -> str:
    """Read a single frontmatter field tolerantly (missing -> default)."""
    try:
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---"):
            return default
        _, fm, _ = text.split("---", 2)
        data = yaml.safe_load(fm) or {}
        val = data.get(key, default)
        return "" if val is None else str(val)
    except Exception:
        return default


def task_title(path: Path | None) -> str:
    return task_field(path, "title") if path else ""


# --- Epic metadata (id -> dir, pretty name, phase) ---------------------------
@dataclass
class Epic:
    id: str
    dirname: str
    path: Path
    name: str = ""
    phase: str = ""


def discover_epics(root: Path) -> dict[str, Epic]:
    epics: dict[str, Epic] = {}
    for d in sorted(root.glob("EPIC-*")):
        if not d.is_dir():
            continue
        m = re.match(r"(EPIC-\d+)", d.name)
        if not m:
            continue
        eid = m.group(1)
        ep = Epic(id=eid, dirname=d.name, path=d)
        epic_md = d / "_epic.md"
        if epic_md.exists():
            head = epic_md.read_text(encoding="utf-8")
            tm = re.search(r"^#\s*EPIC-\d+\s*·\s*(.+)$", head, re.MULTILINE)
            if tm:
                ep.name = tm.group(1).strip()
            pm = re.search(r"\*\*Phase:\*\*\s*([^·\n]+)", head)
            if pm:
                ep.phase = pm.group(1).strip()
        epics[eid] = ep
    return epics


# --- Status aggregation ------------------------------------------------------
def epic_tasks(tasks: dict[str, Task]) -> dict[str, list[Task]]:
    by_epic: dict[str, list[Task]] = {}
    for t in tasks.values():
        by_epic.setdefault(t.epic, []).append(t)
    for v in by_epic.values():
        v.sort(key=lambda t: t.id)
    return by_epic


def status_counts(items: list[Task]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for t in items:
        counts[t.status] = counts.get(t.status, 0) + 1
    return counts


def epic_glyph(items: list[Task]) -> str:
    statuses = {t.status for t in items}
    done = sum(1 for t in items if t.status in SATISFIED)
    if "blocked" in statuses:
        return "⛔"
    if items and done == len(items):
        return "✅"
    if statuses - {"todo"}:
        return "🟡"
    return "⬜"


# --- status command ----------------------------------------------------------
def cmd_status(root: Path, as_json: bool = False, write: bool = True) -> int:
    tasks = load_tasks(root)
    epics = discover_epics(root)
    by_epic = epic_tasks(tasks)

    total = len(tasks)
    overall = status_counts(list(tasks.values()))
    done = sum(v for k, v in overall.items() if k in SATISFIED)

    epic_rows = []
    epics_done = epics_inprog = 0
    for eid in sorted(epics):
        items = by_epic.get(eid, [])
        d = sum(1 for t in items if t.status in SATISFIED)
        glyph = epic_glyph(items)
        if glyph == "✅":
            epics_done += 1
        elif glyph in ("🟡", "⛔"):
            epics_inprog += 1
        epic_rows.append({
            "id": eid,
            "name": epics[eid].name,
            "phase": epics[eid].phase,
            "total": len(items),
            "done": d,
            "glyph": glyph,
        })

    if as_json:
        print(json.dumps({
            "tasks_total": total,
            "tasks_done": done,
            "by_status": overall,
            "epics_total": len(epics),
            "epics_done": epics_done,
            "epics_in_progress": epics_inprog,
            "epics": epic_rows,
        }, indent=2))
        return 0

    print(f"Tasks: {total} total · {done} done/verified")
    print("By status: " + ", ".join(
        f"{k}={overall[k]}" for k in sorted(overall)) or "By status: (none)")
    print(f"Epics: {len(epics)} total · {epics_done} done · {epics_inprog} in-progress")
    print()
    print(f"{'Epic':<9} {'St':<3} {'Prog':<8} Name")
    for r in epic_rows:
        print(f"{r['id']:<9} {r['glyph']:<3} "
              f"{str(r['done']) + '/' + str(r['total']):<8} {r['name']}")

    if write:
        refreshed = refresh_boards(root, tasks, epics, by_epic, overall, total,
                                   done, epics_done, epics_inprog, epic_rows)
        print()
        print(f"Refreshed README + {refreshed} checklist(s).")
    return 0


def refresh_boards(root, tasks, epics, by_epic, overall, total, done,
                   epics_done, epics_inprog, epic_rows) -> int:
    """Rewrite README overall-progress table + each _checklist.md progress."""
    # README overall progress numbers.
    readme = root / "README.md"
    if readme.exists():
        txt = readme.read_text(encoding="utf-8")
        repl = {
            "Epics done": epics_done,
            "Epics in-progress": epics_inprog,
            "Tasks done": done,
            "Tasks in-progress": overall.get("in-progress", 0),
            "Tasks blocked": overall.get("blocked", 0),
        }
        for label, val in repl.items():
            txt = re.sub(
                rf"(\| {re.escape(label)} \| )\d+( \|)",
                rf"\g<1>{val}\g<2>", txt)
        # Per-epic progress + glyph in the status board tables.
        for r in epic_rows:
            txt = re.sub(
                rf"(\| {r['id']} \|[^\n]*?\| )(?:⬜|🟡|✅|⛔)( \| )\d+/\d+( \|)",
                rf"\g<1>{r['glyph']}\g<2>{r['done']}/{r['total']}\g<3>", txt)
        readme.write_text(txt, encoding="utf-8")

    # Per-epic checklists.
    refreshed = 0
    for eid, ep in epics.items():
        chk = ep.path / "_checklist.md"
        if not chk.exists():
            continue
        items = by_epic.get(eid, [])
        d = sum(1 for t in items if t.status in SATISFIED)
        glyph = epic_glyph(items)
        ep_status = {"✅": "done", "🟡": "in-progress",
                     "⛔": "blocked", "⬜": "todo"}[glyph]
        txt = chk.read_text(encoding="utf-8")
        # Replace only the status word, not the rest of the line. Handles both
        # the multi-line layout and the inline `**Status:** x · **Progress:** y`.
        txt = re.sub(r"(\*\*Status:\*\* )[A-Za-z-]+",
                     rf"\g<1>{ep_status}", txt, count=1)
        txt = re.sub(r"(\*\*Progress:\*\* )\d+/\d+",
                     rf"\g<1>{d}/{len(items)}", txt, count=1)
        # Update each task line's checkbox + trailing status.
        for t in items:
            checked = "x" if t.status in SATISFIED else " "
            txt = re.sub(
                rf"(- \[)[ x](\] {re.escape(t.id)} · [^·\n]+· )[a-z-]+( · [^\n]*)?",
                rf"\g<1>{checked}\g<2>{t.status}\g<3>", txt)
        chk.write_text(txt, encoding="utf-8")
        refreshed += 1
    return refreshed


# --- next command ------------------------------------------------------------
def ready_tasks(tasks: dict[str, Task], layer: str | None = None) -> list[Task]:
    satisfied = {k for k, t in tasks.items() if t.status in SATISFIED}
    out = []
    for t in tasks.values():
        if t.status != "todo":
            continue
        if layer is not None and t.layer != layer:
            continue
        if all(dep in satisfied for dep in t.dep_keys()):
            out.append(t)
    return sorted(out, key=lambda t: t.key)


def cmd_next(root: Path, layer: str | None) -> int:
    if layer is not None and layer not in VALID_LAYERS:
        print(f"unknown layer '{layer}'; valid: {', '.join(sorted(VALID_LAYERS))}",
              file=sys.stderr)
        return 2
    tasks = load_tasks(root)
    ready = ready_tasks(tasks, layer=layer)
    if not ready:
        scope = f" in lane '{layer}'" if layer else ""
        print(f"No ready tasks{scope}.")
        return 0
    t = ready[0]
    rel = t.path.relative_to(root.parent.parent.parent) if t.path else ""
    print(f"{t.key}\t{t.layer}\t{task_title(t.path)}")
    if t.path:
        print(rel)
    return 0


# --- review-queue command ----------------------------------------------------
def cmd_review_queue(root: Path) -> int:
    tasks = load_tasks(root)
    queued = sorted(
        (t for t in tasks.values() if t.status == "review-requested"),
        key=lambda t: t.key)
    if not queued:
        print("Review queue is empty.")
        return 0
    print(f"Review queue ({len(queued)}):")
    for t in queued:
        print(f"  {t.key}\t{t.layer}\t{task_title(t.path)}")
    return 0


# --- epic-report command -----------------------------------------------------
def normalize_epic_id(arg: str) -> str:
    m = re.search(r"(\d+)", arg)
    if not m:
        return arg
    return f"EPIC-{int(m.group(1)):02d}"


def cmd_epic_report(root: Path, raw: str) -> int:
    eid = normalize_epic_id(raw)
    epics = discover_epics(root)
    if eid not in epics:
        print(f"unknown epic '{raw}' -> '{eid}'", file=sys.stderr)
        return 2
    ep = epics[eid]
    tasks = load_tasks(root)
    items = sorted((t for t in tasks.values() if t.epic == eid),
                   key=lambda t: t.id)
    counts = status_counts(items)
    done = sum(1 for t in items if t.status in SATISFIED)
    total = len(items)
    complete = total > 0 and done == total

    print(f"# {eid} · {ep.name} — Completion Report")
    print()
    print(f"Phase: {ep.phase or '—'}")
    print(f"Progress: {done}/{total} done/verified "
          f"({'COMPLETE' if complete else 'INCOMPLETE'})")
    print("Status breakdown: " +
          (", ".join(f"{k}={counts[k]}" for k in sorted(counts)) or "(none)"))
    print()
    print("## Tasks")
    for t in items:
        mark = "✓" if t.status in SATISFIED else "·"
        print(f"  {mark} {t.id} [{t.status}] {task_title(t.path)}")
    if not complete:
        pending = [t.id for t in items if t.status not in SATISFIED]
        print()
        print("## Not yet done/verified")
        print("  " + ", ".join(pending))
    return 0


# --- screen-coverage command -------------------------------------------------
LEDGER_ROW = re.compile(
    r"^\|\s*`([a-zA-Z0-9-]+)`\s*\|[^|]*\|[^|]*\|[^|]*\|\s*([^|]+?)\s*\|[^|]*\|\s*$")
EPIC_REF = re.compile(r"EPIC-(\d+)(?:\s*·\s*(T-\d+))?")
# component-token rows look like `| `k-card` | `KCard` | ... |` (3 cells) — skip
# them by requiring the 6-column screen-row shape above.


def parse_ledger(path: Path) -> list[tuple[str, list[tuple[str, str | None]]]]:
    """Return [(screen_key, [(epic_id, task_id|None), ...]), ...]."""
    rows = []
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8").splitlines():
        m = LEDGER_ROW.match(line)
        if not m:
            continue
        screen, epic_cell = m.group(1), m.group(2)
        refs = []
        for em in EPIC_REF.finditer(epic_cell):
            eid = f"EPIC-{int(em.group(1)):02d}"
            tid = em.group(2)
            refs.append((eid, tid))
        if refs:  # only rows that actually name an epic are real screens
            rows.append((screen, refs))
    return rows


def cmd_screen_coverage(root: Path, design_map: Path) -> int:
    rows = parse_ledger(design_map)
    if not rows:
        print(f"No ledger rows found in {design_map}", file=sys.stderr)
        return 2
    tasks = load_tasks(root)
    by_epic = epic_tasks(tasks)

    print(f"Screen coverage: {len(rows)} screens in ledger")
    gaps = []
    ok = 0
    for screen, refs in rows:
        # A screen is covered if at least one owning task is done/verified.
        statuses = []
        any_specific = False
        for eid, tid in refs:
            if tid:
                any_specific = True
                key = f"{eid}/{tid}"
                t = tasks.get(key)
                statuses.append(("done" if t and t.status in SATISFIED
                                 else (t.status if t else "MISSING")))
            else:
                items = by_epic.get(eid, [])
                if not items:
                    statuses.append("EPIC-MISSING")
                elif any(t.status in SATISFIED for t in items):
                    statuses.append("done")
                else:
                    statuses.append("not-done")
        covered = "done" in statuses and "MISSING" not in statuses \
            and "EPIC-MISSING" not in statuses
        owners = ", ".join(
            f"{e}{'·' + t if t else ''}" for e, t in refs)
        if covered:
            ok += 1
        else:
            gaps.append((screen, owners, "/".join(statuses)))

    print(f"  covered (done/verified): {ok}")
    print(f"  gaps: {len(gaps)}")
    for screen, owners, st in gaps:
        print(f"    ⚠ `{screen}` -> {owners} [{st}]")
    return 1 if gaps and "--strict" in sys.argv else 0


# --- CLI ---------------------------------------------------------------------
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tracker.py", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=EPICS_DIR,
                        help="epics directory (default: docs/epics)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_status = sub.add_parser("status", help="counts + refresh boards")
    p_status.add_argument("--json", action="store_true")
    p_status.add_argument("--no-write", action="store_true",
                          help="do not rewrite README/checklists")

    p_next = sub.add_parser("next", help="next ready task")
    p_next.add_argument("--layer", default=None)

    sub.add_parser("review-queue", help="list review-requested tasks")

    p_report = sub.add_parser("epic-report", help="completion report for an epic")
    p_report.add_argument("epic", help="epic number or id, e.g. 0 / 00 / EPIC-00")

    p_cov = sub.add_parser("screen-coverage", help="ledger vs task coverage")
    p_cov.add_argument("--strict", action="store_true",
                       help="exit non-zero if any gap")

    args = parser.parse_args(argv)
    root = args.root

    if args.cmd == "status":
        return cmd_status(root, as_json=args.json, write=not args.no_write)
    if args.cmd == "next":
        return cmd_next(root, layer=args.layer)
    if args.cmd == "review-queue":
        return cmd_review_queue(root)
    if args.cmd == "epic-report":
        return cmd_epic_report(root, args.epic)
    if args.cmd == "screen-coverage":
        return cmd_screen_coverage(root, DESIGN_MAP)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
