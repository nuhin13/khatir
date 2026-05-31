# EPIC-17 · NID Verification (EC API)

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-04, EPIC-10
**Tasks:** 10 · **External services:** Election Commission (EC) verification API (via approved vendor/DPA)

---

## Business goal
Verify a tenant's NID against the Election Commission database, returning a **Matched / Not Matched** result (never raw EC data, never "Porichoy" branding). A paid-tier differentiator that increases landlord trust.

## User-visible outcome
A landlord on a verification-enabled tier (bundle_10+) taps "Verify NID" on a tenant. They consent on the tenant's behalf (consent recorded), the system checks the NID+name+DOB against EC, and shows a clear Matched/Not Matched badge. No raw government data is ever displayed or stored.

## Scope
**In:** EC verification provider behind the AI-gateway-style abstraction (swappable vendor). Consent capture + record (PDPA). Verification result (Matched/Not Matched/Error only) stored, not raw payload. `verify` screen. Tier gating (verification tiers only). VerificationLog for compliance.
**Out:** OCR (EPIC-04, already done). Storing/displaying any EC field beyond the boolean match. Porichoy branding (forbidden).

## Dependencies
EPIC-04 (tenant + NID), EPIC-10 (tier gate — verification is paid-tier), EPIC-16 (consent records + verification log viewer), EPIC-14 (provider abstraction pattern to reuse).

## Data-model changes
- `VerificationLog`: tenant FK, requested_by, result (matched/not_matched/error), provider_ref (opaque), consent_record FK, created_at. **No raw EC fields.**
- Tenant.verification_status updated (unverified → verified/failed).

## API surface
- `POST /api/v1/tenants/{id}/verify` — consent + run verification → Matched/Not Matched.
- `GET /api/v1/tenants/{id}/verification` — last result (boolean + date).
- Admin: verification logs feed into EPIC-16 compliance viewer.

## UI screens (from ledger)
- `verify` → `/tenants/:id/verify` (🟢) — **T-006**

## Feature flags introduced
- `nid_verification_enabled` (default on; kill-switchable if EC API or legal issue).

## Admin config keys
- `ec_verification_provider`, `ec_verification_endpoint` (managed like AI providers — encrypted credentials, DPA reference required).

## Acceptance criteria (epic-level)
- [ ] Verification returns only Matched / Not Matched / Error — never raw EC data.
- [ ] Consent captured + recorded (ConsentRecord) before verification runs.
- [ ] Result stored in VerificationLog (no raw payload); Tenant.verification_status updated.
- [ ] Gated to verification tiers (free tier → upgrade prompt).
- [ ] Never uses "Porichoy" branding; shows neutral "EC verification".
- [ ] Kill-switchable via `nid_verification_enabled`.
- [ ] **Screen `verify` built** per design.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | VerificationLog model + Tenant status update | backend | S | EPIC-04.T-001, EPIC-16.T-001 |
| T-002 | EC verification provider abstraction | backend | M | EPIC-14.T-003 |
| T-003 | Consent capture + ConsentRecord write | backend | S | EPIC-16.T-001 |
| T-004 | Verify endpoint (consent → check → Matched/Not Matched) | backend | M | T-001, T-002, T-003, EPIC-10.T-009 |
| T-005 | Seed verification config + flag | backend | XS | EPIC-00.T-005, EPIC-13.T-001 |
| T-006 | Flutter verify screen | mobile | M | EPIC-04.T-014, T-004 | `verify` |
| T-007 | Verification badge on tenant detail | mobile | S | T-006 |
| T-008 | Verification data layer (mobile) | mobile | S | T-004 |
| T-009 | Verification logs → EPIC-16 compliance viewer | backend | S | T-001, EPIC-16.T-002 |
| T-010 | Verification result privacy test (no raw data) | cross-cutting | S | T-004 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Storing/leaking raw EC data | T-010 asserts only boolean result persisted; provider returns normalized result; raw payload never stored/logged |
| EC API unavailable | `nid_verification_enabled` kill-switch; graceful Error result; provider fallback |
| Consent not captured | Verification refuses to run without a ConsentRecord (T-003 gate) |
| Porichoy branding | UI strings reviewed; neutral "EC verification" only |
| Legal/regulatory change | Kill-switch + DPA reference required on provider config |
