# Adapter: Claude Code
- Entrypoint: auto-loads `CLAUDE.md`.
- Launch one task: `claude -p "Act as <role> agent per workflow/roles/<role>.md. Execute <task-id>."`
- Parallelism: spawn role sub-agents via the Agent tool; isolate parallel writers with git worktrees.
- Cost: use a cheap model for qa/infra/mechanical tasks, the strongest model for architecture tasks.
- Commit: agent commits with `T-YYY:` prefix per CORE finish protocol.
