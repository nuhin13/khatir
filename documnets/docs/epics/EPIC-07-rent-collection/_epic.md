# EPIC-07 · Rent Collection (Web-Link) ★

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-06
**Tasks:** 14 · **External services:** WhatsApp Business API + SMS fallback

---

## Business goal
Landlord sends a rent request; the tenant pays and submits proof via a no-install web link; landlord verifies; a receipt is generated. The signature differentiator and the recurring-use loop that retains landlords. **Second ★ feature.**

## User-visible outcome
The landlord taps "request rent" on a due period; the tenant gets a WhatsApp message with a link to a simple web page (no app, no login). The tenant submits a bKash/Nagad transaction id or screenshot. The landlord reviews and confirms; a receipt PDF is generated and sent back to the tenant. The landlord can also mark cash received directly.

## Scope
**In scope**
- RentRequest creation (from a schedule period, or manual one-off) with a per-request signed link token.
- WhatsApp send (template) + SMS fallback (reusing EPIC-01 NotificationSender).
- Tenant web page (Django template, served by API): pay instructions + proof submission (txn id / screenshot / note). No auth — token-scoped.
- Landlord verify flow → Payment + receipt PDF.
- Direct "mark received" (cash) bypass.
- Reminder cadence (configurable) via Celery.
- Web receipt view for the tenant.

**Out of scope**
- In-app tenant payment (EPIC-19 tenant app).
- Real MFS payment integration/auto-reconcile (manual proof now; auto-verify is later/optional).
- Visitor/maintenance web forms (EPIC-08/25).

## Dependencies
- **Prerequisite:** EPIC-06 (rent schedule provides what's due).
- **External:** WhatsApp Business API (link delivery) + SMS fallback (both via NotificationSender from EPIC-01; console in dev). EPIC-15 templates extend messaging.
- **Design:** screens `rentReq`, `verifyPay`, `receipt` (landlord, 🟢), `webPay`, `webReceipt` (tenant web-link, 🌐). See `07_design_map.md`.

## Data-model changes
- New `rent` app: `RentRequest`, `PaymentProof`, `Payment` per `06_database_schema.md` Domain 5.
- `RentRequestStatus`, `PaymentProofType`, `Channel` enums.
- Indexes: `RentRequest(link_token)`, `RentRequest(lease_id, status)`.

## API surface
- `POST /api/v1/rent-requests` (from schedule or manual), `GET /api/v1/rent-requests` (queue), `GET /{id}`
- `POST /api/v1/rent-requests/{id}/verify`, `/reject`, `/mark-received`
- **Public (token):** `GET /r/{token}` (web page), `POST /r/{token}/proof` (submit), `GET /r/{token}/receipt`
- `GET /api/v1/units/{id}/rent-status` (for home/late-payers)

## UI screens (from ledger)
- `rentReq` → `/rent/request` (🟢) — **T-008**
- `verifyPay` → `/rent/:id/verify` (🟢) — **T-009**
- `receipt` → `/rent/:id/receipt` (🟢) — **T-010**
- `webPay` → `/r/:token` (🌐 Django template) — **T-005**
- `webReceipt` → `/r/:token/receipt` (🌐 Django template) — **T-006**

## Feature flags introduced
None (channel is config).

## Admin-portal config keys
- `rent_reminder_cadence_hours` (json/text, e.g. [24,48]), `rent_link_token_ttl_hours` (int, default 168), `payment_proof_types` (json).

## Test strategy
- Backend: request create + token; web page token-scoping (one token = one request); proof submission; verify→Payment+receipt; mark-received; reminder cadence (eager); receipt PDF; for_user.
- Web: token page renders, proof submit works, expired/invalid token handled.
- Mobile: request screen, verify queue, receipt; states.

## Acceptance criteria (epic-level)
- [ ] Landlord creates a rent request (scheduled or manual); per-request signed token issued.
- [ ] WhatsApp link sent (SMS fallback); dev logs link.
- [ ] Tenant web page (no auth) submits proof; token scopes to exactly one request; expired/invalid handled.
- [ ] Landlord verifies → Payment + receipt PDF; tenant can view web receipt.
- [ ] Direct cash "mark received" works.
- [ ] Reminder cadence from config via Celery.
- [ ] for_user + audit; token never reused/guessable.
- [ ] **Screen coverage:** `rentReq`, `verifyPay`, `receipt`, `webPay`, `webReceipt` built per design.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | RentRequest/PaymentProof/Payment models | backend | M | EPIC-06.T-001 | — |
| T-002 | Signed link-token service | backend | S | T-001 | — |
| T-003 | Rent-request create + queue endpoints | backend | M | T-002, EPIC-06.T-002 | — |
| T-004 | WhatsApp/SMS rent-link send (NotificationSender) | backend | M | T-003, EPIC-01.T-004 | — |
| T-005 | Tenant web pay page (token) | backend(web) | M | T-002 | `webPay` 🌐 |
| T-006 | Proof submit + web receipt page | backend(web) | M | T-005 | `webReceipt` 🌐 |
| T-007 | Verify / reject / mark-received + receipt PDF | backend | M | T-001, EPIC-05.T-003 | — |
| T-008 | Reminder cadence Celery task | backend | S | T-004, EPIC-00.T-006 | — |
| T-009 | Seed rent-collection config | backend | XS | EPIC-00.T-005 | — |
| T-010 | Flutter rent data layer | mobile | M | T-003, T-007 | — |
| T-011 | Flutter rent-request screen | mobile | M | T-010 | `rentReq` |
| T-012 | Flutter verify-payment screen | mobile | M | T-010 | `verifyPay` |
| T-013 | Flutter receipt screen | mobile | M | T-010 | `receipt` |
| T-014 | Late-payers + rent status on home (fill EPIC-03) | mobile | S | T-010, EPIC-03.T-009 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Token guessing / reuse | Signed, single-purpose, expiring tokens; one token = one request; TTL config; tested |
| WhatsApp approval delay | NotificationSender console/stub in dev; SMS fallback; swap when approved |
| Proof fraud (fake txn) | Manual landlord verification is the control; optional MFS auto-verify later |
| Web page abuse | Rate-limit proof submission per token; no enumeration |
| Receipt PDF reuse of EPIC-05 generator | Reuse the PDF/storage pattern from EPIC-05 (don't rebuild) |
