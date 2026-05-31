# EPIC-05 · DMP Form Generation ★ (the wedge)

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-04
**Tasks:** 10 · **External services:** none (PDF generated server-side)

---

## Business goal

Generate the print-ready DMP (Dhaka Metropolitan Police) tenant-registration PDF from a tenant's data. **This is the single feature that drives adoption** — "police form, from home, in 2 minutes." It must be field-accurate to the official form.

## User-visible outcome

After adding a tenant, the landlord sees the DMP form pre-filled with the tenant's and building's data, reviews it, and generates a print-accurate PDF they can preview, download, and share via WhatsApp — without going to the thana or filling anything by hand.

## Scope

**In scope**
- DMP form data assembly (tenant + family + building + landlord fields mapped to the official form layout).
- Server-side PDF generation matching the official DMP template (field-accurate).
- `DMPFormRecord` persistence (which tenant, template version, generated file ref, timestamp).
- Preview screen (`dmp`) + PDF preview/share screen (`dmpPdf`).
- Share via WhatsApp / system share; download.
- Free-tier accessible (the wedge must work on the free tier).

**Out of scope**
- NID verification (EPIC-17).
- Government e-submission/export (EPIC-26).
- Editing tenant data here (done in EPIC-04; this consumes it; minor corrections can route back).

## Dependencies

- **Prerequisite:** EPIC-04 (tenant data incl. encrypted NID — the DMP form needs the full NID, fetched server-side via the audited path).
- **External:** none for generation. **Hard external task:** field-verify the official DMP form template before coding the layout (noted as a risk).
- **Design:** screens `dmp`, `dmpPdf`. See `07_design_map.md`.

## Data-model changes

- New `dmpforms` app: `DMPFormRecord` (tenant FK, building FK snapshot, template_version, pdf_ref, generated_at, generated_by). 
- Stores the generated file ref (in encrypted storage T-003), not the raw field payload beyond what's needed.

## API surface

- `GET /api/v1/tenants/{id}/dmpform` — assembled form data (for preview).
- `POST /api/v1/tenants/{id}/dmpform/pdf` — generate + store PDF, return signed URL.
- `GET /api/v1/dmpforms/{id}` — record + signed PDF URL.

## UI screens (from ledger)
- `dmp` → `/dmpform/:tenantId` (🟢) — **T-007** (review/preview)
- `dmpPdf` → `/dmpform/:id/pdf` (🟢) — **T-008** (PDF preview + share)

## Feature flags introduced
None (the wedge is always on).

## Admin-portal config keys
- `dmp_template_version` (text) — which template layout to use, so updates to the official form can be rolled out via config.

## Test strategy
- Backend: form data assembly maps all required fields; PDF generates with correct values at correct positions (golden-file/field assertions); full NID fetched via audited path only; free-tier can generate; record persisted with template version.
- Mobile: preview shows all fields; generate → PDF preview; share/download work; states.

## Acceptance criteria (epic-level)
- [ ] DMP form data assembled from tenant + family + building + landlord.
- [ ] PDF generated server-side, field-accurate to the official template (template field-verified first).
- [ ] PDF stored (encrypted), returned as signed URL, shareable via WhatsApp + downloadable.
- [ ] `DMPFormRecord` persisted with template version.
- [ ] Works on the free tier.
- [ ] Full NID accessed only via the audited decrypt path (EPIC-04 T-002), never logged.
- [ ] **Screen coverage:** `dmp`, `dmpPdf` built per design.
- [ ] `make test` + `make lint` pass.

## Task list

| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | DMPFormRecord model + migration | backend | S | EPIC-04.T-001 | — |
| T-002 | DMP form data assembler (field mapping) | backend | M | EPIC-04.T-002, EPIC-03.T-001 | — |
| T-003 | PDF generation (template-accurate) | backend | L | T-002 | — |
| T-004 | DMP form data endpoint (preview) | backend | S | T-002 | — |
| T-005 | DMP PDF generate endpoint (+ store, signed URL) | backend | M | T-003, EPIC-04.T-003 | — |
| T-006 | Seed dmp_template_version config | backend | XS | EPIC-00.T-005 | — |
| T-007 | Flutter DMP form preview screen | mobile | M | EPIC-04.T-014, T-004 | `dmp` |
| T-008 | Flutter DMP PDF preview + share screen | mobile | M | T-005, T-007 | `dmpPdf` |
| T-009 | Flutter DMP data layer (repo/models) | mobile | S | T-004, T-005 | — |
| T-010 | Template field-verification + golden test | cross-cutting | M | T-003 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| **Official DMP template not field-verified** (P0 for the wedge) | T-010 verifies against the real form before sign-off; `dmp_template_version` allows updates without redeploy; treat as a release blocker until verified |
| PDF rendering differences across viewers | Use a deterministic generator (reportlab/weasyprint); golden-file test; embed fonts (Bangla) |
| Full NID exposure | Server-side only via audited decrypt; never sent to client or logged; PDF stored encrypted |
| Bangla text in PDF | Embed a Bangla-capable font; test rendering of Bangla fields |
| Template changes by DMP | Versioned template + config key; record stores version used |
