# Khatir — Build Status: EPIC-04 → EPIC-07

_Updated 2026-06-04 — after backend completion run. Source of truth: task frontmatter `status`._  
_Backend on `bench/claude` @ `0b8975f` — full gate green: ruff ✓, migrations ✓, **pytest 713 pass**._

## Dashboard

| Epic | Done | Backend | Mobile |
|---|---|---|---|
| 🟡 EPIC-04 · Tenant Management & NID OCR | **8/16** | 8/8 ✅ | 0/8 |
| 🟡 EPIC-05 · DMP Form Generation | **7/11** | 6/6 ✅ | 0/3 |
| 🟡 EPIC-06 · Lease & Rent Schedule | **6/10** | 6/6 ✅ | 0/4 |
| 🟡 EPIC-07 · Rent Collection (Web-Link) | **9/14** | 9/9 ✅ | 0/5 |
| **TOTAL** | **30/51** | 29/29 ✅ | 0/20 |

## State

- ✅ **All backend done** — EPIC-04..07 backend tasks built, integrated, gate-green (pytest 713). Tenant CRUD+NID encryption+OCR/voice+storage, DMP assemble→PDF→endpoints, lease CRUD+schedule+rollforward, rent requests+link-token+send+proof+verify/receipt.
- ⬜ **All mobile not done** — 20 Flutter tasks. Blocker: **no Flutter SDK on this machine** (`flutter` not on PATH, no fvm, no ~/flutter). Cannot build/verify here.

## Blockers

1. **Mobile (20 tasks)** — Flutter SDK absent. Install Flutter (or run on a machine that has it), then build EPIC-04/05/06/07 `layer: mobile` tasks. All their backend deps are now merged on `bench/claude`, so they are unblocked the moment the toolchain exists.
2. **EPIC-05.T-010 deviation** — DMP field set + positions locked + golden test green, but pixel/overlay match against the official scanned form is unverified (scan requires founder per task §15). Position constants need founder confirmation once the scan arrives.

## EPIC-04 · Tenant Management & NID OCR

| Task | Layer | Status |
|---|---|---|
| T-001 · Tenant + TenantFamilyMember models, enums, migrati | backend | ✅ done |
| T-002 · NID encryption + masking integration | backend | ✅ done |
| T-003 · Encrypted image/object storage helper | backend | ✅ done |
| T-004 · TenantExtractionProvider interface (OCR/ASR abstra | backend | ✅ done |
| T-005 · OCR endpoint (image → fields) | backend | ✅ done |
| T-006 · Voice endpoint (audio → fields) | backend | ✅ done |
| T-007 · Tenant CRUD + family members + for_user | backend | ✅ done |
| T-008 · Free-tier counter hook (count tenants) | backend | ✅ done |
| T-009 · Flutter add-tenant method chooser | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-010 · Flutter NID camera capture + upload | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-011 · Flutter OCR review/edit screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-012 · Flutter voice-fill screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-013 · Flutter manual tenant form | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-014 · Flutter tenants data layer (repos/models/providers | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-015 · Family-members sub-form (shared) | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-016 · Tenant save + route to DMP (wire all 3 paths) | mobile | ⬜ todo (mobile — needs Flutter SDK) |

## EPIC-05 · DMP Form Generation

| Task | Layer | Status |
|---|---|---|
|  ·  |  |  |
| T-001 · DMPFormRecord model + migration | backend | ✅ done |
| T-002 · DMP form data assembler (field mapping) | backend | ✅ done |
| T-003 · PDF generation (template-accurate) | backend | ✅ done |
| T-004 · DMP form data endpoint (preview) | backend | ✅ done |
| T-005 · DMP PDF generate endpoint (+ store, signed URL) | backend | ✅ done |
| T-006 · Seed dmp_template_version config | backend | ✅ done |
| T-007 · Flutter DMP form preview screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-008 · Flutter DMP PDF preview + share screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-009 · Flutter DMP data layer (repo/models) | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-010 · Template field-verification + golden test | cross-cutting | ✅ done |

## EPIC-06 · Lease & Rent Schedule

| Task | Layer | Status |
|---|---|---|
| T-001 · Lease + RentSchedule models, enums, migration | backend | ✅ done |
| T-002 · Rent-schedule generation service | backend | ✅ done |
| T-003 · Lease CRUD + lifecycle endpoints | backend | ✅ done |
| T-004 · Schedule endpoints + unit current-lease | backend | ✅ done |
| T-005 · Monthly roll-forward + overdue Celery task | backend | ✅ done |
| T-006 · Seed due-day/grace config | backend | ✅ done |
| T-007 · Flutter leases data layer | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-008 · Lease create/edit form | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-009 · Lease section on unit detail (fill EPIC-03 placeho | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-010 · Lease list/detail screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |

## EPIC-07 · Rent Collection (Web-Link)

| Task | Layer | Status |
|---|---|---|
| T-001 · RentRequest/PaymentProof/Payment models | backend | ✅ done |
| T-002 · Signed link-token service | backend | ✅ done |
| T-003 · Rent-request create + queue endpoints | backend | ✅ done |
| T-004 · WhatsApp/SMS rent-link send (NotificationSender) | backend | ✅ done |
| T-005 · Tenant web pay page (token) | backend | ✅ done |
| T-006 · Proof submit + web receipt page | backend | ✅ done |
| T-007 · Verify / reject / mark-received + receipt PDF | backend | ✅ done |
| T-008 · Reminder cadence Celery task | backend | ✅ done |
| T-009 · Seed rent-collection config | backend | ✅ done |
| T-010 · Flutter rent data layer | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-011 · Flutter rent-request screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-012 · Flutter verify-payment screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-013 · Flutter receipt screen | mobile | ⬜ todo (mobile — needs Flutter SDK) |
| T-014 · Late-payers + rent status on home (fill EPIC-03) | mobile | ⬜ todo (mobile — needs Flutter SDK) |

## What's done (30)

- **EPIC-04.T-001** — Tenant + TenantFamilyMember models, enums, migration (backend)
- **EPIC-04.T-002** — NID encryption + masking integration (backend)
- **EPIC-04.T-003** — Encrypted image/object storage helper (backend)
- **EPIC-04.T-004** — TenantExtractionProvider interface (OCR/ASR abstraction) (backend)
- **EPIC-04.T-005** — OCR endpoint (image → fields) (backend)
- **EPIC-04.T-006** — Voice endpoint (audio → fields) (backend)
- **EPIC-04.T-007** — Tenant CRUD + family members + for_user (backend)
- **EPIC-04.T-008** — Free-tier counter hook (count tenants) (backend)
- **EPIC-05.T-001** — DMPFormRecord model + migration (backend)
- **EPIC-05.T-002** — DMP form data assembler (field mapping) (backend)
- **EPIC-05.T-003** — PDF generation (template-accurate) (backend)
- **EPIC-05.T-004** — DMP form data endpoint (preview) (backend)
- **EPIC-05.T-005** — DMP PDF generate endpoint (+ store, signed URL) (backend)
- **EPIC-05.T-006** — Seed dmp_template_version config (backend)
- **EPIC-05.T-010** — Template field-verification + golden test (cross-cutting)
- **EPIC-06.T-001** — Lease + RentSchedule models, enums, migration (backend)
- **EPIC-06.T-002** — Rent-schedule generation service (backend)
- **EPIC-06.T-003** — Lease CRUD + lifecycle endpoints (backend)
- **EPIC-06.T-004** — Schedule endpoints + unit current-lease (backend)
- **EPIC-06.T-005** — Monthly roll-forward + overdue Celery task (backend)
- **EPIC-06.T-006** — Seed due-day/grace config (backend)
- **EPIC-07.T-001** — RentRequest/PaymentProof/Payment models (backend)
- **EPIC-07.T-002** — Signed link-token service (backend)
- **EPIC-07.T-003** — Rent-request create + queue endpoints (backend)
- **EPIC-07.T-004** — WhatsApp/SMS rent-link send (NotificationSender) (backend)
- **EPIC-07.T-005** — Tenant web pay page (token) (backend)
- **EPIC-07.T-006** — Proof submit + web receipt page (backend)
- **EPIC-07.T-007** — Verify / reject / mark-received + receipt PDF (backend)
- **EPIC-07.T-008** — Reminder cadence Celery task (backend)
- **EPIC-07.T-009** — Seed rent-collection config (backend)

## What's NOT done (21 — all mobile + 0 backend)

- **EPIC-04.T-009** — Flutter add-tenant method chooser (mobile)
- **EPIC-04.T-010** — Flutter NID camera capture + upload (mobile)
- **EPIC-04.T-011** — Flutter OCR review/edit screen (mobile)
- **EPIC-04.T-012** — Flutter voice-fill screen (mobile)
- **EPIC-04.T-013** — Flutter manual tenant form (mobile)
- **EPIC-04.T-014** — Flutter tenants data layer (repos/models/providers) (mobile)
- **EPIC-04.T-015** — Family-members sub-form (shared) (mobile)
- **EPIC-04.T-016** — Tenant save + route to DMP (wire all 3 paths) (mobile)
- **EPIC-05.** —  ()
- **EPIC-05.T-007** — Flutter DMP form preview screen (mobile)
- **EPIC-05.T-008** — Flutter DMP PDF preview + share screen (mobile)
- **EPIC-05.T-009** — Flutter DMP data layer (repo/models) (mobile)
- **EPIC-06.T-007** — Flutter leases data layer (mobile)
- **EPIC-06.T-008** — Lease create/edit form (mobile)
- **EPIC-06.T-009** — Lease section on unit detail (fill EPIC-03 placeholder) (mobile)
- **EPIC-06.T-010** — Lease list/detail screen (mobile)
- **EPIC-07.T-010** — Flutter rent data layer (mobile)
- **EPIC-07.T-011** — Flutter rent-request screen (mobile)
- **EPIC-07.T-012** — Flutter verify-payment screen (mobile)
- **EPIC-07.T-013** — Flutter receipt screen (mobile)
- **EPIC-07.T-014** — Late-payers + rent status on home (fill EPIC-03) (mobile)

## Next actions

1. Install Flutter SDK (or switch to a machine with it).
2. Build all `layer: mobile` tasks for EPIC-04/05/06/07 (deps satisfied on `bench/claude`).
3. Final wiring **EPIC-04.T-016** (tenant save → DMP, 3 paths) runs last — depends on the mobile screens.

