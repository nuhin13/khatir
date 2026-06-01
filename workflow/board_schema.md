# BOARD.md schema (async message bus)

One line per event, newest at bottom. Format:

`<UTC-timestamp> | <task-id> | <role> | <platform> | <status> | <note>`

- status ∈ {claimed, in-progress, blocked, done, qa-fail}
- note: short reason for blocked/qa-fail, else "-"

Status lifecycle: todo → claimed → in-progress → (qa-fail → in-progress)* → done.
The dispatcher reads task frontmatter `status` as truth; BOARD.md is the human-readable trail.
