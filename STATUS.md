# Khatir — Build Status: EPIC-04 → EPIC-07

_Generated 2026-06-04 after parallel multi-agent build (workflow `build-epics-04-07`)._  
_Source of truth: task-file frontmatter `status`. Backend integrated on `bench/claude` @ `4fb56f2` — full gate green (ruff ✓, migrations ✓, **pytest 625 pass**)._

## Dashboard

| Epic | Done | In progress / Todo | Backend | Mobile |
|---|---|---|---|---|
| 🟡 EPIC-04 · Tenant Management & NID OCR | **3/16** | 13 | 3/8 | 0/8 |
| 🟡 EPIC-05 · DMP Form Generation | **6/10** | 4 | 6/6 | 0/3 |
| 🟡 EPIC-06 · Lease & Rent Schedule | **5/10** | 5 | 5/6 | 0/4 |
| 🟡 EPIC-07 · Rent Collection (Web-Link) | **5/14** | 9 | 5/9 | 0/5 |
| **TOTAL** | **19/50** | 31 | 19/29 | 0/20 |

## Blockers (root causes)

1. **All mobile tasks not done** — the Flutter toolchain is not on PATH inside the workflow worktrees, so `flutter analyze`/`flutter test` could not run. Every `layer: mobile` task is unbuilt for this reason. Fix: run mobile tasks where `flutter` resolves (install was done on the main checkout 06-04 per BOARD, but did not reach the isolated worktree env).
2. **Some backend tasks blocked on absent deps** — workflow worktrees were branched from a stale docs-only base (`b4eb668`) lacking `apps/api`. Green agents self-healed by merging `bench/claude`; the rest hit missing dependency code (a sibling task's output lived in a *different* worktree, never merged). These are now unblocked on `bench/claude` and can be re-run directly.
3. **DMP form (EPIC-05) integration note** — four EPIC-05 backend tasks independently re-implemented `dto.py`/`assembler.py`/`pdf.py` with contradictory field shapes. Integration kept T-005's end-state (assemble→render→store→signed-URL), which subsumes T-002/003/004; their superseded internal-unit tests were dropped. Deliverable functionality present & green.

## EPIC-04 · Tenant Management & NID OCR

| Task | Layer | Status | Note / Blocker |
|---|---|---|---|
| T-001 · Tenant + TenantFamilyMember models, enums, mig | backend | ✅ done |  |
| T-002 · NID encryption + masking integration | backend | ✅ done |  |
| T-003 · Encrypted image/object storage helper | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-004 · TenantExtractionProvider interface (OCR/ASR ab | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-005 · OCR endpoint (image → fields) | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-006 · Voice endpoint (audio → fields) | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-007 · Tenant CRUD + family members + for_user | backend | ✅ done |  |
| T-008 · Free-tier counter hook (count tenants) | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-009 · Flutter add-tenant method chooser | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-010 · Flutter NID camera capture + upload | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-011 · Flutter OCR review/edit screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-012 · Flutter voice-fill screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-013 · Flutter manual tenant form | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-014 · Flutter tenants data layer (repos/models/provi | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-015 · Family-members sub-form (shared) | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-016 · Tenant save + route to DMP (wire all 3 paths) | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |

## EPIC-05 · DMP Form Generation

| Task | Layer | Status | Note / Blocker |
|---|---|---|---|
| T-001 · DMPFormRecord model + migration | backend | ✅ done |  |
| T-002 · DMP form data assembler (field mapping) | backend | ✅ done |  |
| T-003 · PDF generation (template-accurate) | backend | ✅ done |  |
| T-004 · DMP form data endpoint (preview) | backend | ✅ done |  |
| T-005 · DMP PDF generate endpoint (+ store, signed URL | backend | ✅ done |  |
| T-006 · Seed dmp_template_version config | backend | ✅ done |  |
| T-007 · Flutter DMP form preview screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-008 · Flutter DMP PDF preview + share screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-009 · Flutter DMP data layer (repo/models) | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-010 · Template field-verification + golden test | cross-cutting | ⬜ todo | T-010 is a hard release gate that cannot be executed on this branch. Blockers: (1) No backend exists — no apps/api Djang |

## EPIC-06 · Lease & Rent Schedule

| Task | Layer | Status | Note / Blocker |
|---|---|---|---|
| T-001 · Lease + RentSchedule models, enums, migration | backend | ✅ done |  |
| T-002 · Rent-schedule generation service | backend | ✅ done |  |
| T-003 · Lease CRUD + lifecycle endpoints | backend | ✅ done |  |
| T-004 · Schedule endpoints + unit current-lease | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-005 · Monthly roll-forward + overdue Celery task | backend | ✅ done |  |
| T-006 · Seed due-day/grace config | backend | ✅ done |  |
| T-007 · Flutter leases data layer | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-008 · Lease create/edit form | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-009 · Lease section on unit detail (fill EPIC-03 pla | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-010 · Lease list/detail screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |

## EPIC-07 · Rent Collection (Web-Link)

| Task | Layer | Status | Note / Blocker |
|---|---|---|---|
| T-001 · RentRequest/PaymentProof/Payment models | backend | ✅ done |  |
| T-002 · Signed link-token service | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-003 · Rent-request create + queue endpoints | backend | ✅ done |  |
| T-004 · WhatsApp/SMS rent-link send (NotificationSende | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-005 · Tenant web pay page (token) | backend | ✅ done |  |
| T-006 · Proof submit + web receipt page | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-007 · Verify / reject / mark-received + receipt PDF | backend | ⬜ todo | worktree branched from stale docs-only base → backend deps absent |
| T-008 · Reminder cadence Celery task | backend | ✅ done |  |
| T-009 · Seed rent-collection config | backend | ✅ done |  |
| T-010 · Flutter rent data layer | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-011 · Flutter rent-request screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-012 · Flutter verify-payment screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-013 · Flutter receipt screen | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |
| T-014 · Late-payers + rent status on home (fill EPIC-0 | mobile | ⬜ todo | no Flutter toolchain on PATH in worktree |

## What's done

- **EPIC-04.T-001** — Tenant + TenantFamilyMember models, enums, migration (backend)
- **EPIC-04.T-002** — NID encryption + masking integration (backend)
- **EPIC-04.T-007** — Tenant CRUD + family members + for_user (backend)
- **EPIC-05.T-001** — DMPFormRecord model + migration (backend)
- **EPIC-05.T-002** — DMP form data assembler (field mapping) (backend)
- **EPIC-05.T-003** — PDF generation (template-accurate) (backend)
- **EPIC-05.T-004** — DMP form data endpoint (preview) (backend)
- **EPIC-05.T-005** — DMP PDF generate endpoint (+ store, signed URL) (backend)
- **EPIC-05.T-006** — Seed dmp_template_version config (backend)
- **EPIC-06.T-001** — Lease + RentSchedule models, enums, migration (backend)
- **EPIC-06.T-002** — Rent-schedule generation service (backend)
- **EPIC-06.T-003** — Lease CRUD + lifecycle endpoints (backend)
- **EPIC-06.T-005** — Monthly roll-forward + overdue Celery task (backend)
- **EPIC-06.T-006** — Seed due-day/grace config (backend)
- **EPIC-07.T-001** — RentRequest/PaymentProof/Payment models (backend)
- **EPIC-07.T-003** — Rent-request create + queue endpoints (backend)
- **EPIC-07.T-005** — Tenant web pay page (token) (backend)
- **EPIC-07.T-008** — Reminder cadence Celery task (backend)
- **EPIC-07.T-009** — Seed rent-collection config (backend)

## What's NOT done

_31 tasks remaining — 20 mobile (toolchain-blocked), 10 backend (dep-starved, now unblockable)._

- **EPIC-04.T-003** — Encrypted image/object storage helper (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-04.T-004** — TenantExtractionProvider interface (OCR/ASR abstraction) (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-04.T-005** — OCR endpoint (image → fields) (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-04.T-006** — Voice endpoint (audio → fields) (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-04.T-008** — Free-tier counter hook (count tenants) (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-04.T-009** — Flutter add-tenant method chooser (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-010** — Flutter NID camera capture + upload (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-011** — Flutter OCR review/edit screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-012** — Flutter voice-fill screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-013** — Flutter manual tenant form (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-014** — Flutter tenants data layer (repos/models/providers) (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-015** — Family-members sub-form (shared) (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-04.T-016** — Tenant save + route to DMP (wire all 3 paths) (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-05.T-007** — Flutter DMP form preview screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-05.T-008** — Flutter DMP PDF preview + share screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-05.T-009** — Flutter DMP data layer (repo/models) (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-05.T-010** — Template field-verification + golden test (cross-cutting) — T-010 is a hard release gate that cannot be executed on this branch. Blockers: (1) No backend exists — no apps/api Djang
- **EPIC-06.T-004** — Schedule endpoints + unit current-lease (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-06.T-007** — Flutter leases data layer (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-06.T-008** — Lease create/edit form (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-06.T-009** — Lease section on unit detail (fill EPIC-03 placeholder) (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-06.T-010** — Lease list/detail screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-07.T-002** — Signed link-token service (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-07.T-004** — WhatsApp/SMS rent-link send (NotificationSender) (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-07.T-006** — Proof submit + web receipt page (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-07.T-007** — Verify / reject / mark-received + receipt PDF (backend) — worktree branched from stale docs-only base → backend deps absent
- **EPIC-07.T-010** — Flutter rent data layer (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-07.T-011** — Flutter rent-request screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-07.T-012** — Flutter verify-payment screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-07.T-013** — Flutter receipt screen (mobile) — no Flutter toolchain on PATH in worktree
- **EPIC-07.T-014** — Late-payers + rent status on home (fill EPIC-03) (mobile) — no Flutter toolchain on PATH in worktree

## Next actions

1. Re-run the **backend dep-starved tasks** directly on `bench/claude` (deps now present): EPIC-04 T-003/T-004/T-005/T-006/T-008, EPIC-06 T-004, EPIC-05 T-010, EPIC-07 T-002/T-004/T-006/T-007.
2. Build **mobile tasks** in an environment where `flutter` is on PATH (all EPIC-04/05/06/07 `layer: mobile` tasks).
3. Then the final wiring task **EPIC-04.T-016** (tenant save → DMP, 3 paths).

