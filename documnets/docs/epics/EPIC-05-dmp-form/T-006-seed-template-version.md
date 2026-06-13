---
id: T-006
epic: EPIC-05
title: Seed dmp_template_version config
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Seed dmp_template_version config

## 1. Feature goal
Make the DMP template version a config value so layout updates can roll out without redeploy.

## 2. Business logic
`dmp_template_version` SystemConfig (text, e.g. "2026.1"). PDF generation reads it; record stores it.

## 3. What this task DOES
- Seed the config key; tests.

## 5. Files & changes
### Add
- seed migration/command; test
## 6. Database changes
One SystemConfig row.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] seed dmp_template_version (default e.g. 2026.1)
- [ ] idempotent + reversible
- [ ] test
- [ ] ruff clean

## 12. Test plan
### Automated
- test_template_version_seeded
### Manual QA
1. get_config('dmp_template_version') returns default.

## 13. Acceptance criteria
- [ ] Config seeded; reversible; test passes.

## 14. Self-review
- [ ] Read by T-003/T-005
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Bump this when the official form changes; old records keep their generated version.
