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
