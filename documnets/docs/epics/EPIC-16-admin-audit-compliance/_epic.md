# EPIC-16 · Admin — Audit & Compliance

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-11
**Tasks:** 9 · **External services:** none

---

## Business goal
The compliance console: full audit-log search/export, consent records, verification logs, data export/delete requests (PDPA-ready) — the legal defensibility layer required to operate.

## Scope
**In:** Audit-log viewer (admin + end-user AuditEntry) with full filters + CSV export. Consent records browser. Verification logs (result only, no raw payload). Data export/delete request queue with SLA tracking. All scoped to compliance+super roles.
**Out:** Government export feed (EPIC-26). Legal opinion management.

## Dependencies
EPIC-11 (admin shell + AdminAuditEntry from T-002). EPIC-00 T-005 (AuditEntry from core).

## Data-model changes
- `ConsentRecord`: user FK, consent_type, granted_at, revoked_at nullable, expires_at.
- `DataRequest`: user FK, request_type (export/delete), status, sla_due, completed_at, handled_by.
- (VerificationLog lives in EPIC-17; placeholder here for the viewer.)

## API surface
- `GET /admin/api/audit-log` (EPIC-11 T-002 already built; this extends with filters + CSV).
- `GET /admin/api/consent-records`, `GET /admin/api/data-requests`, `POST /{id}/process`.

## Acceptance criteria
- [ ] Audit log searchable by actor/action/entity/date with CSV export.
- [ ] Consent records browseable.
- [ ] Data export/delete requests tracked with SLA due dates.
- [ ] Processing a data request is audited.
- [ ] Compliance+super roles only.
- [ ] MVP complete: this is the last MVP epic. All EPIC-00→16 tasks complete = shippable product.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | ConsentRecord + DataRequest models | backend | S | EPIC-00.T-005 |
| T-002 | Enhanced audit-log endpoint (filters + CSV) | backend | M | EPIC-11.T-002 |
| T-003 | Consent records endpoints | backend | S | T-001 |
| T-004 | Data request queue endpoints | backend | M | T-001, EPIC-11.T-002 |
| T-005 | Seed compliance config (SLA days) | backend | XS | EPIC-00.T-005 |
| T-006 | Enhanced audit log page (Next.js) | admin | M | T-002, EPIC-11.T-008 |
| T-007 | Consent records page (Next.js) | admin | S | T-003 |
| T-008 | Data requests page (Next.js) | admin | M | T-004 |
| T-009 | MVP completion report task | docs | S | all EPIC-00-16 |
