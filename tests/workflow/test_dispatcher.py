from pathlib import Path
from workflow.dispatcher import parse_task, load_tasks, ready_tasks, duplicate_keys

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

# Same local id as TASK_A but a different epic — must NOT collide.
TASK_OTHER_EPIC = """---
id: T-001
epic: EPIC-01
layer: backend
status: todo
depends_on: []
---
body
"""

# Frontmatter with a malformed line (two keys jammed together).
TASK_BROKEN = """---
id: T-009
epic: EPIC-00
layer: backend
status: todo
completed_at: executed_by:
depends_on: []
---
body
"""


def _write(dir_path, name, text):
    p = dir_path / name
    p.write_text(text, encoding="utf-8")
    return p


def test_parse_task_reads_frontmatter(tmp_path):
    p = _write(tmp_path, "T-001.md", TASK_A)
    t = parse_task(p)
    assert t.id == "T-001"
    assert t.status == "done"
    assert t.depends_on == []


def test_task_key_is_epic_qualified(tmp_path):
    p = _write(tmp_path, "T-001.md", TASK_A)
    t = parse_task(p)
    assert t.key == "EPIC-00/T-001"


def test_ready_tasks_only_returns_unblocked_todo(tmp_path):
    _write(tmp_path, "T-001.md", TASK_A)
    _write(tmp_path, "T-002.md", TASK_B)
    _write(tmp_path, "T-003.md", TASK_C)
    ready = [t.id for t in ready_tasks(tmp_path)]
    assert ready == ["T-002"]  # T-001 done, T-003 blocked by T-002


def test_same_local_id_across_epics_does_not_collide(tmp_path):
    # Two files both with local id T-001 but different epics. Files are
    # discovered by the T-*.md glob, so each epic needs its own subdir.
    e0 = tmp_path / "EPIC-00"; e0.mkdir()
    e1 = tmp_path / "EPIC-01"; e1.mkdir()
    _write(e0, "T-001.md", TASK_A)
    _write(e1, "T-001.md", TASK_OTHER_EPIC)
    tasks = load_tasks(tmp_path)
    assert set(tasks.keys()) == {"EPIC-00/T-001", "EPIC-01/T-001"}


def test_depends_on_resolves_within_same_epic(tmp_path):
    # EPIC-01/T-001 is todo (not done), so EPIC-00/T-002 must still be ready
    # because its dep T-001 resolves to EPIC-00/T-001 (done), not EPIC-01/T-001.
    e0 = tmp_path / "EPIC-00"; e0.mkdir()
    e1 = tmp_path / "EPIC-01"; e1.mkdir()
    _write(e0, "T-001.md", TASK_A)            # EPIC-00/T-001 done
    _write(e0, "T-002.md", TASK_B)            # EPIC-00/T-002 dep [T-001]
    _write(e1, "T-001.md", TASK_OTHER_EPIC)   # EPIC-01/T-001 todo
    ready = {t.key for t in ready_tasks(tmp_path)}
    assert "EPIC-00/T-002" in ready
    assert "EPIC-01/T-001" in ready  # no deps


def test_malformed_yaml_file_is_skipped_not_crashing(tmp_path):
    _write(tmp_path, "T-001.md", TASK_A)
    _write(tmp_path, "T-009.md", TASK_BROKEN)
    tasks = load_tasks(tmp_path)  # must not raise
    assert "EPIC-00/T-001" in tasks
    assert "EPIC-00/T-009" not in tasks  # broken file skipped


def test_task_with_missing_dependency_stays_blocked(tmp_path):
    # T-002 depends on T-001, but T-001 was never defined. It must NOT
    # become ready (the dep is absent from `done`, so the check fails).
    _write(tmp_path, "T-002.md", TASK_B)
    ready = [t.key for t in ready_tasks(tmp_path)]
    assert ready == []


def test_ready_tasks_can_filter_by_epic(tmp_path):
    # T-001 done in EPIC-00; EPIC-01/T-001 has no deps. Filtering to EPIC-01
    # returns only the EPIC-01 task.
    e0 = tmp_path / "EPIC-00"; e0.mkdir()
    e1 = tmp_path / "EPIC-01"; e1.mkdir()
    _write(e0, "T-001.md", TASK_A)            # EPIC-00/T-001 done
    _write(e0, "T-002.md", TASK_B)            # EPIC-00/T-002 ready
    _write(e1, "T-001.md", TASK_OTHER_EPIC)   # EPIC-01/T-001 ready
    ready = {t.key for t in ready_tasks(tmp_path, epics={"EPIC-01"})}
    assert ready == {"EPIC-01/T-001"}


def test_duplicate_keys_are_detected(tmp_path):
    # Two files in the same epic both claiming id T-002.
    e0 = tmp_path / "EPIC-08"; e0.mkdir()
    dup = TASK_B.replace("epic: EPIC-00", "epic: EPIC-08")
    _write(e0, "T-002-first.md", dup)
    _write(e0, "T-002-second.md", dup)
    dups = duplicate_keys(tmp_path)
    assert "EPIC-08/T-002" in dups
    assert len(dups["EPIC-08/T-002"]) == 2
