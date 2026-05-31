---
id: T-005
epic: EPIC-05
title: DMP PDF generate endpoint (+ store, signed URL)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, EPIC-04.T-003]
blocks: [T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · DMP PDF generate endpoint (+ store, signed URL)

## 1. Feature goal
`POST /tenants/{id}/dmpform/pdf` assembles data, renders the PDF, stores it encrypted, records a DMPFormRecord, and returns a signed URL.

## 2. Business logic
Assemble (T-002) → render (T-003) → store encrypted (EPIC-04 T-003) → create DMPFormRecord (T-001) with template_version → return signed URL. Free-tier allowed. Audit. Owner-scoped.

## 3. What this task DOES
- Endpoint orchestrating the pipeline; record creation; signed URL; audit; tests (mocked render/storage).

## 5. Files & changes
### Add
- view + service + tests/test_dmp_pdf.py
### Update
- urls

## 6. Database changes
Creates a DMPFormRecord per generation.
## 7. API changes
| POST | /api/v1/tenants/{id}/dmpform/pdf | owner | 201 (signed URL) |
| GET | /api/v1/dmpforms/{id} | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] orchestrate assemble→render→store→record
- [ ] signed URL returned
- [ ] free-tier allowed
- [ ] audit on generate
- [ ] owner-scoped; GET record endpoint
- [ ] Tests (mocked render+storage)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_generate_pdf_returns_signed_url, test_record_created, test_free_tier_allowed, test_scoped
### Manual QA
1. Generate PDF → get signed URL → opens the PDF.

## 13. Acceptance criteria
- [ ] PDF generated, stored, recorded, signed URL returned; free-tier ok; tests + lint pass.

## 14. Self-review
- [ ] Audited; full NID server-side only; record has template_version
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Generation can be sync (acceptable for a single form) or Celery for resilience. Signed URL TTL modest (e.g. 1h).
