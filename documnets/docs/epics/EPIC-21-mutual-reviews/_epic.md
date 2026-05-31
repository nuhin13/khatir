# EPIC-21 · Mutual Reviews (Private, Consent-Gated)

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-19, EPIC-13
**Tasks:** 10 · **External services:** none

---

## Business goal
Allow landlord and tenant to leave **mutual, private, consent-gated** reviews of each other after a tenancy — visible ONLY to the two parties (or to a future counterparty strictly with explicit consent). **Never public, never a searchable reputation database** (illegal under the Cyber Security Ordinance 2025). The most legally-sensitive feature; ships behind a kill-switch and is private by construction.

## User-visible outcome
After a lease period, a tenant can privately rate/review their landlord (`tenReview`) and a landlord can privately review a tenant. Each party sees reviews ABOUT them only with the reviewer's consent. There is no public listing, no aggregate score browseable by strangers, no way to look up a person's reviews without their consent. The `tenReview` and `tenRecord` screens drive the tenant side.

## Scope
**In:** Review model (mutual, double-blind until both submit or consent given). Strict consent gating for any visibility beyond the reviewer↔reviewee pair. Kill-switch (`reviews_feature`). `tenReview` + `tenRecord` screens. Audit + consent records.
**Out:** ANY public display, search, ranking, or cross-party aggregation (architecturally forbidden). Showing a person's reviews to a NEW counterparty without that person's explicit, logged consent (deferred + heavily gated; not in MVP of this epic).

## Dependencies
EPIC-19 (tenant app + tenRecord), EPIC-13 (kill-switch reviews_feature), EPIC-16 (consent records + audit), EPIC-06 (lease defines the relationship).

## Data-model changes
- `Review`: lease FK, reviewer FK, reviewee FK, rating, comment, visibility (private/consented), consent_record FK nullable, created_at. Double-blind reveal logic.
- Consent gating leverages EPIC-16 ConsentRecord.

## API surface
- `POST /api/v1/leases/{id}/reviews` — submit a review (kill-switch + relationship gate).
- `GET /api/v1/me/reviews` — reviews ABOUT me (only with reviewer consent / mutual reveal).
- No public/search endpoint exists. By design.

## UI screens (from ledger)
- `tenReview` → `/tenant/review` (🟢) — **T-005**
- `tenRecord` → already built in EPIC-19 T-010; this epic wires its review-submission to the backend — **T-006** (integration)

## Feature flags introduced
- Uses `reviews_feature` kill-switch (EPIC-13 T-004 seeds it).

## Acceptance criteria (epic-level)
- [ ] Mutual private reviews between the two lease parties only.
- [ ] No public, searchable, or cross-party aggregated view exists anywhere (verified by test).
- [ ] Any visibility beyond reviewer↔reviewee requires an explicit, logged ConsentRecord.
- [ ] Double-blind: reviews revealed only after both submit (or per consent rules).
- [ ] Kill-switchable via `reviews_feature`.
- [ ] Audit on submit + any consent grant.
- [ ] **Screen coverage:** `tenReview`, `tenRecord` (wired) built.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Review model + double-blind reveal logic | backend | M | EPIC-06.T-001, EPIC-16.T-001 |
| T-002 | Review submit + view endpoints (kill-switch + consent) | backend | M | T-001, EPIC-13.T-002 |
| T-003 | Consent-gated visibility service | backend | M | T-001, EPIC-16.T-001 |
| T-004 | Seed review config | backend | XS | EPIC-00.T-005 |
| T-005 | Flutter tenant review screen | mobile | M | EPIC-19.T-011, T-002 | `tenReview` |
| T-006 | Wire tenRecord review submission (EPIC-19) | mobile | S | EPIC-19.T-010, T-002 | `tenRecord` |
| T-007 | Landlord-side review entry | mobile | M | T-002 |
| T-008 | Review data layer (mobile) | mobile | S | T-002 |
| T-009 | "No public reputation" architecture test | cross-cutting | M | T-002, T-003 |
| T-010 | Kill-switch + consent enforcement test | cross-cutting | S | T-002, T-003 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| **Becoming a public/searchable reputation DB (illegal)** | T-009 asserts NO endpoint returns reviews by person across leases or to non-parties; architecturally no public read; kill-switch |
| Showing reviews without consent | T-003 + T-010: visibility beyond the pair requires a logged ConsentRecord; default private |
| Defamation exposure | Private-only; double-blind; disclaimer; kill-switch; reviews tied to a real lease relationship (no anonymous strangers) |
| Feature enabled before legal clearance | Ships behind `reviews_feature`; default reviewable before enabling in production |
