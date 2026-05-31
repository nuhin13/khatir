---
id: T-003
epic: EPIC-26
title: Submission adapter interface (pluggable, stub default)
layer: backend
size: M
status: todo
preferred_agent: codex
depends_on: [T-002]
blocks: []
external_services: [gov_submission]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Submission adapter interface (pluggable, stub default)

## 1. Feature goal
GovSubmissionAdapter ABC: submit(package) -> result. Default impl = produce-package-only (no real submission). A real gov endpoint can be plugged later without changing callers. Tests (stub).

## 2. Business logic
GovSubmissionAdapter ABC: submit(package) -> result. Default impl = produce-package-only (no real submission). A real gov endpoint can be plugged later without changing callers. Tests (stub).

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/govexport/... or features/govexport/... per layer; tests.

## 6–10.
DB as described; backend. Consent + audit on export. Flag: [] (default OFF).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core implementation per goal
- [ ] Consent respected + audit (where applicable)
- [ ] Tests
- [ ] ruff + mypy clean

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
GovSubmissionAdapter ABC: submit(package) -> result. Default impl = produce-package-only (no real submission). A real gov endpoint can be plugged later without changing callers. Tests (stub).
