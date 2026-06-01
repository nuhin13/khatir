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
