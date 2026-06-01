"""Collect objective benchmark metrics from a finished platform workspace.

Usage:
    python3 workflow/bench_metrics.py <workspace-path> [--epics EPIC-00,EPIC-01]

Prints task-completion, commit, and rework counters as plain `key\tvalue` lines
so the human only has to fill the subjective rubric fields by hand.
"""
from __future__ import annotations
import subprocess
import sys
from pathlib import Path

from dispatcher import load_tasks  # type: ignore


def _git(ws: Path, *args: str) -> str:
    out = subprocess.run(
        ["git", "-C", str(ws), *args],
        capture_output=True, text=True,
    )
    return out.stdout


def collect(ws: Path, epics: set[str] | None) -> dict[str, object]:
    epics_root = ws / "documnets" / "docs" / "epics"
    tasks = load_tasks(epics_root) if epics_root.exists() else {}
    scoped = {
        k: t for k, t in tasks.items()
        if epics is None or t.epic in epics
    }
    done = [k for k, t in scoped.items() if t.status == "done"]

    log = _git(ws, "log", "--oneline").splitlines()
    # Count commits whose subject starts with a task tag like "T-001:".
    tagged = [ln for ln in log if _looks_tagged(ln)]

    return {
        "scoped_tasks": len(scoped),
        "tasks_marked_done": len(done),
        "completion_pct": round(100 * len(done) / len(scoped), 1) if scoped else 0.0,
        "total_commits": len(log),
        "task_tagged_commits": len(tagged),
        "rework_proxy_extra_commits": max(0, len(log) - len(tagged)),
    }


def _looks_tagged(oneline: str) -> bool:
    # "<sha> T-001: summary"
    parts = oneline.split(" ", 1)
    if len(parts) != 2:
        return False
    subject = parts[1].strip()
    return subject[:2] == "T-" and ":" in subject[:8]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    ws = Path(sys.argv[1]).expanduser().resolve()
    epics: set[str] | None = None
    if "--epics" in sys.argv:
        i = sys.argv.index("--epics")
        epics = {e.strip() for e in sys.argv[i + 1].split(",") if e.strip()}
    for k, v in collect(ws, epics).items():
        print(f"{k}\t{v}")
