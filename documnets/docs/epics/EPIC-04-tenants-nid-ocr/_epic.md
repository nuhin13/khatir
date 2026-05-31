# EPIC-04 · Tenant Management & NID OCR

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-03
**Tasks:** 16 · **External services:** OCR provider (Cloud Vision or chosen) + ASR provider (Bangla voice); both behind a swappable interface, moved under the AI gateway in EPIC-14

---

## Business goal

Register a tenant under a unit by capturing identity from an NID photo (OCR), Bangla voice, or manual entry — storing NID data encrypted and masked. This is the data that feeds the DMP form (the wedge) and leases.

## User-visible outcome

From a unit (or the home DMP CTA), the landlord chooses how to add a tenant: snap the NID (OCR auto-extracts name, NID number, DOB, address), speak the details in Bangla (voice fill), or type manually. They review/correct the extracted fields, add family members, and save. The tenant is created (encrypted NID), ready for a DMP form.

## Scope

**In scope**
- Tenant + TenantFamilyMember models (NID encrypted + masked).
- Add-tenant method chooser (`addTenant`): OCR / voice / manual.
- OCR pipeline: image upload → OCR provider → structured fields → editable review.
- Voice pipeline: Bangla audio → ASR → field extraction → editable review.
- Manual entry form.
- Encrypted image storage; masked display.
- Free-tier hook: count toward the 2-tenant free limit (enforcement lands with EPIC-10).
- Audit on tenant create.

**Out of scope**
- DMP form PDF (EPIC-05) — the flows end by routing to the DMP screen.
- NID verification against EC (EPIC-17, P1) — this epic is OCR/extraction only.
- Lease creation (EPIC-06).
- The AI provider abstraction layer itself (EPIC-14) — here we integrate a provider directly behind a thin interface that EPIC-14 later swaps for the gateway.

## Dependencies

- **Prerequisite:** EPIC-03 (units to attach tenants to).
- **External:** an OCR provider (e.g. Google Cloud Vision) and a Bangla ASR provider; credentials via env; behind a `TenantExtractionProvider` interface so EPIC-14 can route through the gateway later.
- **Design:** screens `addTenant`, `ocr`, `voice`, `manualTenant`. See `07_design_map.md`.

## Data-model changes

- New `tenants` app: `Tenant` (nid_number_enc, nid_number_masked, photo_ref encrypted, verification_status, …) + `TenantFamilyMember`. Per `06_database_schema.md` Domain 3.
- `VerificationStatus` enum (default `unverified`; real verification is EPIC-17).
- Encryption via `core.encryption` (EPIC-00 T-005).

## API surface

- `POST /api/v1/tenants/ocr` — image → extracted fields (does not persist tenant yet).
- `POST /api/v1/tenants/voice` — audio → extracted fields.
- `POST /api/v1/tenants` — create tenant (from reviewed fields) under a unit.
- `GET /api/v1/tenants/{id}`, `GET /api/v1/units/{id}/tenants`, `PATCH /api/v1/tenants/{id}`.
- Family members nested under tenant.

## UI screens (from ledger)
- `addTenant` → `/tenants/add` (🟢) — **T-009**
- `ocr` → `/tenants/add/ocr` (🟢) — **T-010, T-011**
- `voice` → `/tenants/add/voice` (🟢) — **T-012**
- `manualTenant` → `/tenants/add/manual` (🟢) — **T-013**

## Feature flags introduced
- `voice_tenant_entry` (default on) — allows disabling the voice path if the ASR provider is unreliable.

## Admin-portal config keys
- `ocr_provider_key`, `asr_provider_key` (text) — which provider to use (placeholder until EPIC-14 manages providers properly).

## Test strategy
- Backend: OCR/voice endpoints (mocked provider) return structured fields; tenant create encrypts NID + stores masked; image stored encrypted; family members; for_user scoping; audit. Encryption round-trip + masking asserted.
- Mobile: method chooser; camera capture → review → save; voice record → review; manual form; all states; free-tier counter hook.

## Acceptance criteria (epic-level)
- [ ] Landlord adds a tenant via OCR, voice, or manual, under a unit.
- [ ] NID number encrypted at rest + masked everywhere; NID image stored encrypted.
- [ ] Extracted fields are editable before save.
- [ ] Family members captured.
- [ ] Free-tier counter increments (enforcement in EPIC-10).
- [ ] Provider behind a swappable interface (EPIC-14-ready).
- [ ] Audit on tenant create; for_user isolation.
- [ ] **Screen coverage:** `addTenant`, `ocr`, `voice`, `manualTenant` built per design.
- [ ] `make test` + `make lint` pass.

## Task list

| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Tenant + TenantFamilyMember models, enums, migration | backend | M | EPIC-00.T-005, EPIC-03.T-001 | — |
| T-002 | NID encryption + masking integration | backend | S | T-001 | — |
| T-003 | Encrypted image/object storage helper | backend | M | EPIC-00.T-005 | — |
| T-004 | TenantExtractionProvider interface (OCR/ASR abstraction) | backend | M | T-001 | — |
| T-005 | OCR endpoint (image → fields) | backend | M | T-003, T-004 | — |
| T-006 | Voice endpoint (audio → fields) | backend | M | T-003, T-004 | — |
| T-007 | Tenant CRUD + family members + for_user | backend | M | T-002, EPIC-03.T-002 | — |
| T-008 | Free-tier counter hook (count tenants) | backend | S | T-007 | — |
| T-009 | Flutter add-tenant method chooser | mobile | M | EPIC-03.T-007 | `addTenant` |
| T-010 | Flutter NID camera capture + upload | mobile | M | T-005, T-009 | `ocr` |
| T-011 | Flutter OCR review/edit screen | mobile | M | T-010 | `ocr` |
| T-012 | Flutter voice-fill screen | mobile | M | T-006, T-009 | `voice` |
| T-013 | Flutter manual tenant form | mobile | M | T-009 | `manualTenant` |
| T-014 | Flutter tenants data layer (repos/models/providers) | mobile | M | T-007 | — |
| T-015 | Family-members sub-form (shared) | mobile | S | T-014 | — |
| T-016 | Tenant save + route to DMP (wire all 3 paths) | mobile | S | T-011, T-012, T-013, T-014 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| OCR accuracy on real NIDs | Always show editable review; never auto-save raw OCR; field-level confidence if provider gives it |
| Bangla ASR quality | `voice_tenant_entry` flag to disable; manual fallback always present |
| NID data leakage | Encrypted at rest, masked display, never logged; image encrypted; result stored not raw provider payload |
| Provider lock-in | TenantExtractionProvider interface; EPIC-14 swaps to gateway without touching screens |
| Free-tier bypass | Counter at create (T-008); hard enforcement in EPIC-10 |
