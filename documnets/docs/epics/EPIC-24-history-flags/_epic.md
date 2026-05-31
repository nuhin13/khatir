# EPIC-24 · Tenancy History Flags (P2 — Heavily Gated)

**Phase:** P2 · **Status:** todo · **Depends on:** EPIC-21, EPIC-13
**Tasks:** 12 · **External services:** none

---

## Business goal
Allow a tenant's verified tenancy history (on-time payment record, lease completion) to be shared with a PROSPECTIVE landlord — **strictly with the tenant's explicit, per-request, logged consent**, surfacing only factual, tenant-controlled records. **Never a blacklist, never public, never without consent.** This is the legally riskiest concept in the product and is built defensively, behind a kill-switch, P2.

## CRITICAL legal framing
This is NOT a credit bureau or reputation database. It is a **tenant-controlled, consent-per-share** mechanism: the tenant chooses to share their OWN factual record (e.g. "12 on-time payments, lease completed") with a specific prospective landlord, for a specific application. The tenant can see exactly what is shared, with whom, and revoke. No landlord can query a tenant without that tenant initiating/consenting. If this framing cannot be guaranteed in implementation, the feature stays disabled.

## Scope
**In:** Tenant-initiated, consent-per-share history records (factual payment/lease completion data only). A share grant to a specific prospective landlord with expiry. Full transparency to the tenant (what/who/when) + revoke. Kill-switch (`history_flags_feature`). Heavy audit + consent records.
**Out:** ANY landlord-initiated lookup of a tenant. ANY subjective "flag" or rating in this epic (subjective lives in EPIC-21, private). ANY cross-tenant or public aggregation. ANY persistence of shared data on the receiving landlord's side beyond the consented view window.

## Dependencies
EPIC-21 (consent + review infra), EPIC-13 (kill-switch history_flags_feature), EPIC-16 (consent records + compliance), EPIC-06/07 (the factual payment/lease data).

## Data-model changes
- `HistoryShare`: tenant FK, recipient_landlord FK, scope (what factual fields), consent_record FK, expires_at, revoked_at, created_at.
- Read view computes factual stats (on-time payment count, lease completion) at share time — no subjective data.

## API surface
- `POST /api/v1/me/history-shares` — tenant creates a share to a specific landlord (consent).
- `GET /api/v1/me/history-shares` — tenant sees their shares (transparency).
- `POST /api/v1/me/history-shares/{id}/revoke` — tenant revokes.
- `GET /api/v1/history-shares/{token}` — recipient views (only while active + consented).
- NO landlord-initiated tenant lookup endpoint. By design.

## UI screens
- No dedicated prototype screen — built into the tenant record/share flow + a recipient view. (Design-wise an extension of `tenRecord`.)

## Feature flags introduced
- Uses `history_flags_feature` kill-switch (EPIC-13 T-004 seeds it; default reviewable).

## Acceptance criteria (epic-level)
- [ ] Only the tenant can initiate sharing their OWN factual history.
- [ ] Each share targets a specific landlord, is consent-logged, has expiry, and is tenant-revocable.
- [ ] Shared data is factual only (payment punctuality, lease completion) — no subjective flags.
- [ ] Tenant has full transparency (what/who/when) + revoke.
- [ ] NO landlord-initiated lookup exists; NO public/aggregate path (verified by test).
- [ ] Kill-switchable; heavy audit.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | HistoryShare model + factual-stats computation | backend | M | EPIC-07.T-001, EPIC-16.T-001 |
| T-002 | Tenant-initiated share endpoints (consent + expiry) | backend | M | T-001, EPIC-13.T-002 |
| T-003 | Recipient view endpoint (token, active-only) | backend | M | T-001 |
| T-004 | Revoke + transparency endpoints | backend | S | T-001 |
| T-005 | Seed history-flags config | backend | XS | EPIC-00.T-005 |
| T-006 | Tenant share UI (from tenRecord) | mobile | M | EPIC-19.T-010, T-002 |
| T-007 | Tenant transparency + revoke UI | mobile | M | T-004 |
| T-008 | Recipient view (web-link, factual only) | backend(web) | M | T-003 |
| T-009 | History-share data layer (mobile) | mobile | S | T-002 |
| T-010 | "No landlord-initiated lookup" architecture test | cross-cutting | M | T-002, T-003 |
| T-011 | Consent + expiry + revoke enforcement test | cross-cutting | S | T-002, T-004 |
| T-012 | Factual-only data test (no subjective fields) | cross-cutting | S | T-001 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| **Becoming an illegal tenant blacklist** | Tenant-initiated + consent-per-share only; T-010 proves no landlord lookup exists; kill-switch; P2 behind legal review |
| Subjective data leaking in | T-012 asserts only factual computed stats are shared; no review/flag text |
| Shared data persisting on recipient side | Token view only, expiry-enforced; recipient cannot export; T-011 |
| Consent bypass | Every share requires a logged ConsentRecord; default deny |
