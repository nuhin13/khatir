# Adapter: Cursor
- Entrypoint: auto-loads `.cursor/rules/workflow.md` (also reads `AGENTS.md`).
- Launch one task: background agent on the task, role prompt = `workflow/roles/<role>.md`.
- Parallelism: multiple background agents, isolate writers with worktrees.
- Commit: `T-YYY:` prefix.
