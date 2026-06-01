# Adapter: Gemini CLI
- Entrypoint: auto-loads `GEMINI.md`.
- Launch one task: `gemini -p "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: one process per task, each in its own git worktree.
- Cost: select model tier per task weight.
- Commit: `T-YYY:` prefix.
