---
id: T-004
epic: EPIC-18
title: Generate + edit + PDF endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003, EPIC-05.T-003]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Generate + edit + PDF endpoints

## 1. Feature goal
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.

## 2. Business logic
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/leasedocs/... or leases/ extension; tests.

## 6–10.
DB: as described. No external (beyond gateway). Tier-gated + audited + owner-scoped. 

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `views.py` (3 APIViews) + `urls.py` (mounted in `config/urls.py`) + `serializers.py` + `pdf.py`; `services.py` extended (`edit_lease_document`, `render_lease_document_pdf`)
- [x] tier gate + audit + owner scope — `ai_lease_enabled` flag + `check_can_verify` (402); `audit()` on generate/edit/pdf; all ids scoped through `Lease.objects.for_user` (foreign → 404)
- [x] Tests — `tests/test_api.py` (13: gate/flag/scope/draft-lock/required-clause/pdf+disclaimer/audit) + `tests/test_pdf.py`; leasedocs suite 61 pass
- [x] ruff clean — `ruff check .` passes; `makemigrations --check` no changes (no model change)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] Required clauses guaranteed; disclaimer present; conventions
### Deviations from spec
- Endpoints live in a new `khatir/leasedocs` REST surface (`views.py`/`urls.py`/`serializers.py`) rather than extending `leases/`, keeping the lease-document concern self-contained. Tier gate reuses billing `check_can_verify` (AI lease generation is a paid feature like NID verification). PDF rendering is a deterministic, dependency-free single-page renderer (`pdf.py`, mirroring the EPIC-05 DMP approach) stored via the shared `khatir.core.storage` encrypted store → signed URL, so the generate→store→signed-URL pipeline is end-to-end runnable and golden-testable without a real PDF toolchain. No DB/model change → no migration.
### Files touched (actual)
- `apps/api/khatir/leasedocs/views.py` (new) — `GenerateLeaseDocumentView`, `LeaseDocumentEditView`, `LeaseDocumentPdfView`, `DocumentLockedError`, owner-scope helper.
- `apps/api/khatir/leasedocs/urls.py` (new) + `apps/api/config/urls.py` — mounted under `/api/v1/`.
- `apps/api/khatir/leasedocs/serializers.py` (new) — `LeaseDocumentSerializer`, `LeaseDocumentEditSerializer`.
- `apps/api/khatir/leasedocs/pdf.py` (new) — `render_lease_pdf` (deterministic clause render).
- `apps/api/khatir/leasedocs/flags.py` (new) — `ai_lease_enabled` resolver.
- `apps/api/khatir/leasedocs/services.py` — added `edit_lease_document`, `render_lease_document_pdf`, `RenderedLeasePdf`.
- `apps/api/khatir/leasedocs/tests/test_api.py` (new, 13) + `tests/test_pdf.py` (new).
## 15. Notes
POST /leases/{id}/generate-document (AI draft). PATCH /lease-documents/{id} (edit clauses). POST /lease-documents/{id}/pdf (render via EPIC-05 PDF infra → signed URL). Tier-gated. Audited. Owner-scoped.
