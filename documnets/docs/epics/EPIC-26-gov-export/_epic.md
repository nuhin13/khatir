# EPIC-26 · Government Export (DMP Bulk Submission)

**Phase:** P3 · **Status:** todo · **Depends on:** EPIC-05, EPIC-16
**Tasks:** 6 · **External services:** future DMP/government e-submission endpoint (if/when available)

---

## Business goal
When/if the DMP offers an electronic submission channel, let landlords export their tenant DMP records in the official bulk format (or submit directly) — closing the loop from "fill the form" to "file it with the police." Until the gov channel exists, this produces a compliant export package.

## Scope
**In:** Bulk export of a landlord's DMP records in an official-compatible format (structured file + PDFs). A submission adapter interface so a real gov endpoint can be plugged in later. Consent + audit. Admin-configurable format version.
**Out:** Building the gov endpoint (not ours). Real-time gov status (until the channel exists). Anything that bypasses the per-tenant consent already captured in EPIC-04/05.

## Dependencies
EPIC-05 (DMP records + PDFs), EPIC-16 (consent + audit + export request infra), EPIC-03/04 (the underlying data).

## Data-model changes
- `GovExport`: landlord FK, period, format_version, file_ref, record_count, status (generated/submitted), created_at.

## API surface
- `POST /api/v1/gov-export` — generate a bulk export package for a period.
- `GET /api/v1/gov-export/{id}` — download the package (signed URL).
- (Future) `POST /api/v1/gov-export/{id}/submit` — submit via the gov adapter when available.

## UI screens
- No dedicated prototype screen — an export action in the landlord/DMP area (lightweight UI; primarily a backend capability).

## Feature flags introduced
- `gov_export_enabled` (default off — enable when the format/channel is confirmed).

## Acceptance criteria (epic-level)
- [ ] Landlord generates a bulk DMP export package (structured file + the relevant PDFs) for a period.
- [ ] Submission adapter interface exists (pluggable for a future real gov endpoint); default impl produces the package only.
- [ ] Consent + audit on export; respects existing per-tenant consent.
- [ ] Format version admin-configurable.
- [ ] Off by default behind `gov_export_enabled`.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | GovExport model + migration | backend | S | EPIC-05.T-001 |
| T-002 | Bulk export package builder (structured + PDFs) | backend | M | T-001, EPIC-05.T-003 |
| T-003 | Submission adapter interface (pluggable, stub default) | backend | M | T-002 |
| T-004 | Export endpoints (generate + download) | backend | M | T-002, EPIC-16.T-004 |
| T-005 | Seed gov-export config + flag | backend | XS | EPIC-13.T-001 |
| T-006 | Export UI action (landlord/DMP area) | mobile | S | T-004 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Gov format unknown/changes | format_version config; adapter interface isolates format; off by default |
| Submitting without consent | Reuses per-tenant consent from EPIC-04/05; export audited; no submission without the adapter + consent |
| Premature enablement | `gov_export_enabled` defaults OFF; enable only when the official channel/format is confirmed |
