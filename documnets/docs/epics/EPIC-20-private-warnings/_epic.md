# EPIC-20 · Private Warnings

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-06, EPIC-13
**Tasks:** 10 · **External services:** none

---

## Business goal
Let a landlord issue a **private, formal warning notice** to their own tenant (late rent, lease violation) — generating a documented notice they can deliver. **Strictly private** between that landlord and tenant; never public, never a shared "blacklist." Legally gated + kill-switchable.

## User-visible outcome
From a unit/lease, the landlord issues a warning (type, reason, date) → a formatted notice (Bangla/English) they can share with their tenant via the existing channels. A private record is kept. The `warning` screen drives this.

## Scope
**In:** Warning model (private to the landlord-tenant relationship). Warning notice generation (PDF, reuse EPIC-05). `warning` screen. Kill-switchable (`warnings_feature` from EPIC-13). Consent/legal disclaimer. Audit.
**Out:** ANY public or cross-landlord visibility (forbidden — Cyber Security Ordinance risk). Sharing a tenant's warnings with other landlords (that's the forbidden "history flags" — explicitly NOT this; see EPIC-24 which is P2 and itself heavily gated).

## Dependencies
EPIC-06 (lease/tenant context), EPIC-13 (kill-switch `warnings_feature`), EPIC-05 (PDF), EPIC-16 (audit/consent).

## Data-model changes
- `Warning`: lease FK, tenant FK, landlord FK, warning_type, reason, issued_at, notice_ref (PDF), acknowledged_at nullable. Private scope (landlord-tenant only).

## API surface
- `POST /api/v1/leases/{id}/warnings` — issue.
- `GET /api/v1/leases/{id}/warnings` — list (landlord's own only).
- `POST /api/v1/warnings/{id}/notice` — generate notice PDF.

## UI screens (from ledger)
- `warning` → `/lease/:id/warning` (🟢) — **T-005**

## Feature flags introduced
- Uses `warnings_feature` kill-switch (EPIC-13 T-004 already seeds it).

## Acceptance criteria (epic-level)
- [ ] Landlord issues a private warning to their own tenant; record kept.
- [ ] Notice PDF generated (reuse EPIC-05) + shareable via existing channels.
- [ ] STRICTLY private: never visible to other landlords or the public; scoped to the issuing landlord + that tenant.
- [ ] Gated by `warnings_feature` kill-switch (off → feature hidden).
- [ ] Audit on issue; legal disclaimer shown.
- [ ] **Screen `warning` built** per design.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Warning model + migration | backend | S | EPIC-06.T-001 |
| T-002 | Warning issue + list endpoints (scoped + kill-switch) | backend | M | T-001, EPIC-13.T-002 |
| T-003 | Warning notice PDF (reuse EPIC-05) | backend | S | T-002, EPIC-05.T-003 |
| T-004 | Seed warning types config | backend | XS | EPIC-00.T-005 |
| T-005 | Flutter warning screen | mobile | M | EPIC-06.T-007, T-002 | `warning` |
| T-006 | Warning notice share | mobile | S | T-003, EPIC-05.T-008 |
| T-007 | Warning data layer (mobile) | mobile | S | T-002 |
| T-008 | Warnings on unit/lease detail | mobile | S | T-007 |
| T-009 | Kill-switch enforcement test (feature hidden when off) | cross-cutting | S | T-002 |
| T-010 | Privacy test (never cross-landlord/public) | cross-cutting | S | T-002 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Warnings leaking cross-landlord (legal: defamation/Cyber Security Ordinance) | T-010 asserts strict landlord-tenant scope; no endpoint exposes another landlord's warnings; never aggregated |
| Misuse as a public blacklist | Architecturally impossible — no public/shared read path exists; kill-switchable |
| Feature enabled before legal sign-off | `warnings_feature` kill-switch defaults reviewable; ship behind it |
