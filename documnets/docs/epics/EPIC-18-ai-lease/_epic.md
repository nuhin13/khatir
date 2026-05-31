# EPIC-18 · AI Lease Generation

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-06, EPIC-14
**Tasks:** 10 · **External services:** AI chat/generation provider (via AI gateway)

---

## Business goal
Generate a DNCC/DSCC-compliant tenancy agreement from the lease data using the AI gateway — "Smart lease, compliant contract" — producing a shareable PDF, raising the product from rent-tracking to full lease lifecycle.

## User-visible outcome
From a lease, the landlord taps "Generate smart lease." The AI drafts a compliant Bangla/English tenancy agreement from the lease terms (rent, advance, dates, parties), shown for review/edit, then rendered as a PDF to share/sign. The `lease` screen presents this.

## Scope
**In:** AI lease generation via gateway (lease category provider). Template/clauses scaffold (compliant base + AI-filled specifics). Review/edit before finalize. PDF render (reuse EPIC-05 infra). `lease` screen. Tier-gated (paid). Disclaimer (not legal advice).
**Out:** E-signature (future). Legal review workflow. Multi-language beyond bn/en.

## Dependencies
EPIC-06 (lease data), EPIC-14 (AI gateway lease provider), EPIC-05 (PDF infra), EPIC-10 (tier gate).

## Data-model changes
- `LeaseDocument`: lease FK, content_json (clauses), pdf_ref, generated_by, model_used, generated_at, status (draft/final).

## API surface
- `POST /api/v1/leases/{id}/generate-document` — AI draft → clauses.
- `PATCH /api/v1/lease-documents/{id}` — edit clauses.
- `POST /api/v1/lease-documents/{id}/pdf` — render PDF.

## UI screens (from ledger)
- `lease` → `/lease/:id/document` (🟢) — **T-006**

## Feature flags introduced
- `ai_lease_enabled` (default on; kill-switchable).

## Admin config keys
- `lease_template_version`, `lease_disclaimer_text` (bn/en).

## Acceptance criteria (epic-level)
- [ ] AI generates a compliant lease draft from lease data via the gateway.
- [ ] Landlord reviews + edits clauses before finalizing.
- [ ] PDF rendered (reuse EPIC-05) + shareable.
- [ ] Tier-gated; disclaimer shown ("not legal advice").
- [ ] Kill-switchable.
- [ ] **Screen `lease` built** per design.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | LeaseDocument model + migration | backend | S | EPIC-06.T-001 |
| T-002 | Lease clause template/scaffold | backend | M | T-001 |
| T-003 | AI lease generation service (via gateway) | backend | M | T-002, EPIC-14.T-007 |
| T-004 | Generate + edit + PDF endpoints | backend | M | T-003, EPIC-05.T-003 |
| T-005 | Seed lease config + flag + disclaimer | backend | XS | EPIC-00.T-005, EPIC-13.T-001 |
| T-006 | Flutter lease document screen | mobile | M | EPIC-06.T-007, T-004 | `lease` |
| T-007 | Clause review/edit UI | mobile | M | T-006 |
| T-008 | Lease PDF preview + share | mobile | S | T-006, EPIC-05.T-008 |
| T-009 | Lease document data layer (mobile) | mobile | S | T-004 |
| T-010 | Compliance disclaimer + tier gate test | cross-cutting | S | T-004 |
