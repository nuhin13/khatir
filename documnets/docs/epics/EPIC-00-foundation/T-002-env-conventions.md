---
id: T-002
epic: EPIC-00
title: Env conventions & .env.example
layer: infra
size: XS
status: todo
preferred_agent: codex
depends_on: [T-001]
blocks: [T-003, T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Env conventions & .env.example

## 1. Feature goal
Create the canonical `.env.example` at repo root listing every environment variable the system uses, so any contributor can copy it to `.env` and run locally.

## 2. Business logic
Config layering per `03_env_and_config.md`: secrets/infra in env (Layer 1), code defaults (Layer 2), business values in DB (Layer 3). This task only handles Layer 1's template. **No real secrets** — dummy/empty values only.

## 3. What this task DOES
- Create `.env.example` at repo root with every key from `03_env_and_config.md` §2, grouped with comments.
- Confirm `.env` is gitignored (from T-001).

## 4. What this task does NOT do
- Does not create a real `.env`.
- Does not wire env reading into Django (that's T-004).

## 5. Files & changes
### Add
- `.env.example` — full canonical key list (copy from `03_env_and_config.md` §2)
### Update
- none (verify `.gitignore` already excludes `.env`)
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
None (placeholders only).

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] `.env.example` created at repo root
- [ ] All groups present: Core, Database, Redis, Auth/JWT, Object storage, Field encryption, Messaging, AI Gateway, Observability, Admin
- [ ] Every key has a comment or sensible dummy
- [ ] `.env` confirmed gitignored
- [ ] No real secret values committed

## 12. Test plan
### Manual QA
1. `cp .env.example .env` produces a file that later tasks can read without missing-key errors for local dev.

## 13. Acceptance criteria
- [ ] `.env.example` matches `03_env_and_config.md` §2 key list.
- [ ] No secrets committed.

## 14. Self-review
- [ ] Keys match architecture doc
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Source of truth for the key list is `docs/architecture/03_env_and_config.md` §2. Copy it verbatim, keeping comments.
