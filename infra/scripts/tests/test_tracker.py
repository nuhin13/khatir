"""Unit tests for tracker.py using a temp fixture epic tree."""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import tracker  # noqa: E402


def write_task(epic_dir: Path, tid: str, status: str,
               depends_on: list[str] | None = None, title: str = "",
               layer: str = "backend", epic: str = "EPIC-00") -> None:
    deps = "[" + ", ".join(depends_on or []) + "]"
    epic_dir.mkdir(parents=True, exist_ok=True)
    (epic_dir / f"{tid}-x.md").write_text(
        f"---\nid: {tid}\nepic: {epic}\nlayer: {layer}\n"
        f"status: {status}\ndepends_on: {deps}\ntitle: {title or tid}\n---\n\nbody\n",
        encoding="utf-8")


@pytest.fixture
def fixture_root(tmp_path: Path) -> Path:
    root = tmp_path / "epics"
    e0 = root / "EPIC-00-foundation"
    write_task(e0, "T-001", "done", title="Init")
    write_task(e0, "T-002", "todo", depends_on=["T-001"], title="Second", layer="infra")
    write_task(e0, "T-003", "todo", depends_on=["T-002"], title="Third")
    write_task(e0, "T-004", "review-requested", title="Fourth")
    # cross-epic dependency, unmet
    e1 = root / "EPIC-01-onboarding-auth"
    write_task(e1, "T-001", "todo", depends_on=["EPIC-00/T-003"],
               title="Cross", epic="EPIC-01")
    (e0 / "_epic.md").write_text(
        "# EPIC-00 · Foundation & Scaffold\n\n**Phase:** — · **Status:** todo\n",
        encoding="utf-8")
    (e1 / "_epic.md").write_text(
        "# EPIC-01 · Onboarding\n\n**Phase:** MVP · **Status:** todo\n",
        encoding="utf-8")
    return root


def test_next_returns_dep_met_task(fixture_root: Path):
    tasks = tracker.load_tasks(fixture_root)
    ready = tracker.ready_tasks(tasks)
    # T-001 done -> T-002 ready; T-003 blocked by T-002 (todo); EPIC-01 blocked.
    assert ready[0].key == "EPIC-00/T-002"
    assert "EPIC-00/T-003" not in {t.key for t in ready}


def test_next_blocked_skips_unmet_dep(fixture_root: Path):
    tasks = tracker.load_tasks(fixture_root)
    ready_keys = {t.key for t in tracker.ready_tasks(tasks)}
    assert "EPIC-01/T-001" not in ready_keys  # cross-epic dep unmet


def test_next_layer_filter(fixture_root: Path):
    tasks = tracker.load_tasks(fixture_root)
    ready = tracker.ready_tasks(tasks, layer="infra")
    assert [t.key for t in ready] == ["EPIC-00/T-002"]
    assert tracker.ready_tasks(tasks, layer="admin") == []


def test_status_counts(fixture_root: Path):
    tasks = tracker.load_tasks(fixture_root)
    counts = tracker.status_counts(list(tasks.values()))
    assert counts["done"] == 1
    assert counts["todo"] == 3
    assert counts["review-requested"] == 1


def test_review_queue(fixture_root: Path, capsys):
    rc = tracker.cmd_review_queue(fixture_root)
    out = capsys.readouterr().out
    assert rc == 0
    assert "EPIC-00/T-004" in out
    assert "EPIC-00/T-001" not in out


def test_status_runs_and_no_write(fixture_root: Path, capsys):
    rc = tracker.cmd_status(fixture_root, write=False)
    out = capsys.readouterr().out
    assert rc == 0
    assert "EPIC-00" in out and "EPIC-01" in out


def test_epic_report_incomplete(fixture_root: Path, capsys):
    rc = tracker.cmd_epic_report(fixture_root, "0")
    out = capsys.readouterr().out
    assert rc == 0
    assert "INCOMPLETE" in out
    assert "T-001" in out


def test_normalize_epic_id():
    assert tracker.normalize_epic_id("0") == "EPIC-00"
    assert tracker.normalize_epic_id("00") == "EPIC-00"
    assert tracker.normalize_epic_id("EPIC-05") == "EPIC-05"
