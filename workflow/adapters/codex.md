# Adapter: Codex CLI
- Entrypoint: auto-loads `AGENTS.md`.
- Launch one task: `codex exec "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: one process per task, each in its own git worktree.
- Cost: pick the reasoning effort/model per task weight.
- Commit: `T-YYY:` prefix.
