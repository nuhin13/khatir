"""Read task frontmatter, build the dependency graph, list ready tasks.

Task IDs (T-001..) reset per epic, so a globally-unique key is `<epic>/<id>`
(e.g. ``EPIC-00/T-001``). A task's ``depends_on`` entries are epic-local by
default (a bare ``T-003`` means "T-003 in my own epic"); a fully-qualified
``EPIC-XX/T-YYY`` entry references another epic.
"""
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

    @property
    def key(self) -> str:
        """Globally-unique task key: ``<epic>/<id>``."""
        return f"{self.epic}/{self.id}"

    def dep_keys(self) -> list[str]:
        """Resolve each ``depends_on`` entry to a global ``<epic>/<id>`` key.

        Bare ids (``T-003``) resolve within this task's own epic. Cross-epic
        refs may be written ``EPIC-00/T-005`` (slash) or ``EPIC-00.T-005``
        (dot) — both normalize to the same global key.
        """
        out = []
        for dep in self.depends_on:
            if "/" in dep:
                out.append(dep)
            elif "." in dep:
                out.append(dep.replace(".", "/", 1))
            else:
                out.append(f"{self.epic}/{dep}")
        return out


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
    """Parse every ``T-*.md`` under ``root``, keyed by global ``<epic>/<id>``.

    Files with malformed frontmatter are skipped rather than aborting the run.
    """
    tasks: dict[str, Task] = {}
    for p in sorted(root.rglob("T-*.md")):
        try:
            t = parse_task(p)
        except (ValueError, KeyError, yaml.YAMLError):
            continue
        tasks[t.key] = t
    return tasks


def duplicate_keys(root: Path) -> dict[str, list[Path]]:
    """Return any global key claimed by more than one task file.

    Duplicates mean two files share an ``<epic>/<id>``; ``load_tasks`` would
    silently keep only one, so the dispatcher must flag them for a human.
    """
    seen: dict[str, list[Path]] = {}
    for p in sorted(root.rglob("T-*.md")):
        try:
            t = parse_task(p)
        except (ValueError, KeyError, yaml.YAMLError):
            continue
        seen.setdefault(t.key, []).append(p)
    return {k: v for k, v in seen.items() if len(v) > 1}


def ready_tasks(root: Path, epics: set[str] | None = None) -> list[Task]:
    """Tasks whose deps are all ``done`` and which are themselves ``todo``.

    ``done`` status is evaluated over the WHOLE graph (a cross-epic dep must
    still be satisfied); ``epics`` only narrows which ready tasks are returned.
    """
    tasks = load_tasks(root)
    done = {key for key, t in tasks.items() if t.status == "done"}
    out = []
    for t in tasks.values():
        if t.status != "todo":
            continue
        if epics is not None and t.epic not in epics:
            continue
        if all(dep in done for dep in t.dep_keys()):
            out.append(t)
    return sorted(out, key=lambda t: t.key)


if __name__ == "__main__":
    import sys

    root = Path(__file__).resolve().parent.parent / "documnets" / "docs" / "epics"
    # Optional: `--epics EPIC-00,EPIC-01` narrows output to those epics.
    epics: set[str] | None = None
    if "--epics" in sys.argv:
        i = sys.argv.index("--epics")
        epics = {e.strip() for e in sys.argv[i + 1].split(",") if e.strip()}

    dups = duplicate_keys(root)
    if dups:
        print("WARNING: duplicate task keys (a human must resolve these):")
        for key, paths in dups.items():
            names = ", ".join(p.name for p in paths)
            print(f"  {key}: {names}")
        print()
    for t in ready_tasks(root, epics=epics):
        print(f"{t.key}\t{t.layer}")
