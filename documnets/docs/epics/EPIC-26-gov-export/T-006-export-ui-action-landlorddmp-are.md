---
id: T-006
epic: EPIC-26
title: Export UI action (landlord/DMP area)
layer: mobile
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-004]
blocks: []
external_services: []
feature_flags: [gov_export_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Export UI action (landlord/DMP area)

## 1. Feature goal
A lightweight export action in the DMP/landlord area: pick period → generate → download/share package. Hidden if gov_export_enabled off. Widget test.

## 2. Business logic
A lightweight export action in the DMP/landlord area: pick period → generate → download/share package. Hidden if gov_export_enabled off. Widget test.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
No DB; consumes gov-export endpoints; mobile 🟢. Consent + audit on export. Flag: [gov_export_enabled] (default OFF).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Consent respected + audit (where applicable)
- [ ] Tests
- [ ] analyze + test pass

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [ ] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [ ] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
### Files touched (actual)
## 15. Notes
A lightweight export action in the DMP/landlord area: pick period → generate → download/share package. Hidden if gov_export_enabled off. Widget test.
