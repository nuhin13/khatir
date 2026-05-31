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
