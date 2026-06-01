## Claude Code specifics
- MCP servers configured in `.mcp.json` at repo root (GitHub, Postgres for inspection).
- Prefer `make next LAYER=backend` style dispatch; honor `preferred_agent: claude-code` tasks first.
- Use the planning/extended-thinking mode for `size: L` and architectural tasks.
