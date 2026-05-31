# EPIC-19 · Tenant App (In-App Tenant Experience)

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-07, EPIC-08, EPIC-06
**Tasks:** 14 · **External services:** none (reuses existing)

---

## Business goal
Give tenants their own in-app experience (the tenant role shell from EPIC-02): see their lease, pay rent in-app, report maintenance, view receipts — converting the web-link tenants into engaged app users and enabling the mutual-review loop (EPIC-21).

## User-visible outcome
A tenant logs in (tenant role), lands on a home with their rent status + quick actions, can view their lease, pay rent (same proof flow as the web-link but in-app), report maintenance, and browse past receipts. Optionally records a private rating of their landlord (feeds EPIC-21).

## Scope
**In:** Tenant role home (`tenHome`), lease view (`tenLease`), in-app pay (`tenPay`), maintenance report (`tenMaint`), receipts list (`tenReceipts`), and the tenant record/rating entry (`tenRecord`) that feeds EPIC-21. Tenant data layer (reads their own lease/rent/receipts via tenant-scoped endpoints). Linking a tenant account to a Tenant record.
**Out:** The mutual review *display* + landlord-side (EPIC-21 — `tenReview` lives there). Public anything (never).

## Dependencies
EPIC-02 (tenant role shell), EPIC-06 (lease), EPIC-07 (rent/pay/receipt), EPIC-08 (maintenance). EPIC-21 consumes `tenRecord`.

## Data-model changes
- `TenantAccount` link: connects a User (role=tenant) to a Tenant record (so the app knows whose lease to show). Could reuse Tenant.linked_user_id from EPIC-04.
- Tenant-scoped read permissions (a tenant sees only their own lease/rent/receipts).

## API surface (tenant-scoped, `/api/v1/me/`)
- `GET /api/v1/me/lease` — the tenant's current lease.
- `GET /api/v1/me/rent` — their rent schedule + requests.
- `POST /api/v1/me/rent/{id}/pay` — submit proof in-app (reuses EPIC-07 proof logic).
- `GET /api/v1/me/receipts` — their receipts.
- `POST /api/v1/me/maintenance` — report maintenance (reuses EPIC-08).

## UI screens (from ledger)
- `tenHome` → `/tenant/home` (🟢) — **T-005**
- `tenLease` → `/tenant/lease` (🟢) — **T-006**
- `tenPay` → `/tenant/pay/:id` (🟢) — **T-007**
- `tenMaint` → `/tenant/maintenance` (🟢) — **T-008**
- `tenReceipts` → `/tenant/receipts` (🟢) — **T-009**
- `tenRecord` → `/tenant/record` (🟢) — **T-010** (feeds EPIC-21)

## Feature flags introduced
- `tenant_app_enabled` (default on).

## Acceptance criteria (epic-level)
- [ ] Tenant logs in → tenant shell → home with rent status + quick actions.
- [ ] Tenant views their lease, pays rent in-app (proof reuses EPIC-07), reports maintenance (reuses EPIC-08), views receipts.
- [ ] All tenant data strictly scoped to their own records (can't see others').
- [ ] Tenant record/rating entry captured privately (feeds EPIC-21; never public).
- [ ] **Screen coverage:** tenHome, tenLease, tenPay, tenMaint, tenReceipts, tenRecord built.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Tenant-account link + tenant-scoped permissions | backend | M | EPIC-04.T-001, EPIC-02.T-002 | — |
| T-002 | Tenant self-service endpoints (/me/lease, /me/rent, /me/receipts) | backend | M | T-001, EPIC-06.T-004, EPIC-07.T-001 | — |
| T-003 | In-app pay endpoint (reuse EPIC-07 proof) | backend | S | T-002, EPIC-07.T-006 | — |
| T-004 | Tenant maintenance report endpoint (reuse EPIC-08) | backend | S | T-002, EPIC-08.T-002 | — |
| T-005 | Tenant home screen | mobile | M | EPIC-02.T-004, T-002 | `tenHome` |
| T-006 | Tenant lease view screen | mobile | M | T-002 | `tenLease` |
| T-007 | Tenant in-app pay screen | mobile | M | T-003 | `tenPay` |
| T-008 | Tenant maintenance report screen | mobile | M | T-004 | `tenMaint` |
| T-009 | Tenant receipts list screen | mobile | M | T-002 | `tenReceipts` |
| T-010 | Tenant record/rating entry screen | mobile | M | T-002 | `tenRecord` |
| T-011 | Tenant data layer (mobile) | mobile | M | T-002, T-003, T-004 | — |
| T-012 | Tenant shell wiring (fill EPIC-02 placeholders) | mobile | S | T-005, EPIC-02.T-004 | — |
| T-013 | Seed tenant app flag | backend | XS | EPIC-13.T-001 | — |
| T-014 | Tenant data isolation test | cross-cutting | S | T-002 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Tenant sees another tenant's data | T-014 isolation test; all /me/ endpoints scoped to linked Tenant only |
| Account-to-tenant linking ambiguity | Explicit TenantAccount link; a User maps to exactly one Tenant record per active lease |
| Duplicate pay logic | Reuse EPIC-07 proof + verify logic; in-app pay just feeds the same pipeline |
| Review feeding public exposure | tenRecord is strictly private; EPIC-21 enforces consent-gated, never-public |
