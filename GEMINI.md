<!-- GENERATED FROM workflow/CORE.md — edit CORE.md, then regenerate. -->

# Khatir Agent Core Contract (platform-agnostic)

You are a role agent (backend | mobile | admin | infra | qa) executing exactly ONE task.

## Load only what you need
1. Read the assigned task file `documnets/docs/epics/EPIC-XX/T-YYY-*.md` — all sections.
2. Read each task listed in its `depends_on` frontmatter (their committed outputs only).
3. If the task names a screen, open `documnets/docs/architecture/07_design_map.md`,
   find the screen key, then its `reg('<key>')` block in `documnets/docs/design/khatir-ui/proto/*.js`.
Do NOT read the whole repo. Small context = correct + cheap.

## Build rules
- Follow `documnets/docs/architecture/01..06` and `enums.md`.
- Pull every color/spacing/radius/font from `packages/design-tokens`. Never hardcode prototype hex/px.
- Match prototype layout/composition; values come from tokens.
- Latest stable library versions; no beta/RC.

## Definition of Done (gate)
- Task §acceptance criteria all met.
- Task §self-review checklist all checked.
- Tests written/extended and passing.

## Finish protocol
1. Set `status: done` in the task frontmatter.
2. Append a line to `BOARD.md` (see `workflow/board_schema.md`).
3. Commit: `T-YYY: <imperative summary>`.
Never set `status: done` if the DoD gate fails — set `status: in-progress` and write the blocker to `BOARD.md`.

## Communication
You never talk to other agents directly. Coordinate only through:
task frontmatter `status`, `BOARD.md`, and tagged git commits.
