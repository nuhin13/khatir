---
id: T-003
epic: EPIC-26
title: Submission adapter interface (pluggable, stub default)
layer: backend
size: M
status: done
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
- [x] Core implementation per goal — `khatir/govexport/submission.py`
- [x] Consent respected + audit (where applicable) — `govexport.submit` audit row (no PII)
- [x] Tests — `khatir/govexport/tests/test_submission.py` (8 tests)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; consent + audit; flag-gated (default off); tests pass.
## 14. Self-review
- [x] Off by default; format versioned; adapter pluggable; conventions
### Deviations from spec
- Adapter is flag-agnostic and OFF-by-default via the `gov_submission_adapter`
  config (seeded `stub` by T-005) rather than a boolean feature flag, mirroring
  the messaging sender factory; the `gov_export_enabled` flag stays enforced at
  the endpoint layer (T-004/T-005) so the adapter is unit-testable in isolation.
- The default `ProducePackageOnlyAdapter` performs no network call and does not
  mutate `GovExportStatus` (left at `generated`); it still writes a
  `govexport.submit` audit row so the no-op attempt is traceable. Consent was
  already enforced by the T-002 builder at package-build time; the adapter never
  re-reads PII (operates only on the already-consent-filtered `BuiltPackage`).
### Files touched (actual)
- `apps/api/khatir/govexport/submission.py` (new) — `GovSubmissionAdapter` ABC,
  `ProducePackageOnlyAdapter` default, `SubmissionResult`, registry + `get_adapter`/`submit_package`
- `apps/api/khatir/govexport/tests/test_submission.py` (new) — 8 tests
## 15. Notes
GovSubmissionAdapter ABC: submit(package) -> result. Default impl = produce-package-only (no real submission). A real gov endpoint can be plugged later without changing callers. Tests (stub).
