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
