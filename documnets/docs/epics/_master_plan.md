# Master Epic Plan

> The complete program of work, in execution order. Every epic listed with its business goal, the value it unlocks, task-count estimate, hard dependencies, external services, and the gate that defines "done." Agents read this to understand sequence; `README.md` tracks live status.

**File location:** `docs/epics/_master_plan.md`

---

## How to use this document

- Epics execute **roughly top-to-bottom**, but the real ordering constraint is **`depends_on`**, not the number. An epic can start the moment its dependencies are `verified` — several MVP epics can run in parallel once their prerequisites are met.
- **Phase** tells you *when in the product story* an epic belongs (MVP first, then P1, P2, P3). Don't build P1 before MVP is shippable.
- **Task count** is an estimate finalized when that epic's task files are written (Step 3+).
- **★** marks the wedge — the single most important feature for initial adoption.

---

## Dependency graph (high level)

```
EPIC-00 Foundation
   │
   ├──▶ EPIC-01 Onboarding & Auth
   │        │
   │        └──▶ EPIC-02 Role & Profile
   │                 │
   │                 └──▶ EPIC-03 Properties & Units
   │                          │
   │                          └──▶ EPIC-04 Tenants & NID OCR
   │                                   │
   │                                   ├──▶ EPIC-05 DMP Form ★ (the wedge)
   │                                   │
   │                                   └──▶ EPIC-06 Lease & Rent Schedule
   │                                            │
   │                                            ├──▶ EPIC-07 Rent Collection
   │                                            │        │
   │                                            └──▶ EPIC-08 Expenses
   │                                                     │
   │                                       EPIC-07 + 08 ─┴──▶ EPIC-09 Dashboard
   │
   ├──▶ EPIC-10 Pricing & Free Limit   (needs 04 for tenant metering)
   │
   └──▶ EPIC-11 Admin Portal Foundation
            │
            ├──▶ EPIC-12 Admin · Pricing & Users   (needs 10, 11)
            ├──▶ EPIC-13 Admin · Feature Flags & Kill-switch   (needs 11)
            ├──▶ EPIC-14 Admin · AI Providers   (needs 11)
            ├──▶ EPIC-15 Admin · Notifications   (needs 11)
            └──▶ EPIC-16 Admin · Audit & Compliance   (needs 11)

  ═══════════════  MVP COMPLETE  ═══════════════

P1: EPIC-17 NID Verify (→04) · EPIC-18 AI Lease (→06,14) · EPIC-19 Tenant App (→07)
    EPIC-20 Warnings (→06,13) · EPIC-21 Reviews (→19) · EPIC-22 Manager Tier (→03)
    EPIC-23 Chatbot (→14)

P2: EPIC-24 History Flags (→20) · EPIC-25 Gatekeeper (→03)

P3: EPIC-26 Government Export (→16)
```

---

# PHASE: FOUNDATION

## EPIC-00 · Foundation & Scaffold
**Phase:** — (pre-product) · **Est. tasks:** ~16 · **Depends on:** none
**External services:** none (Sentry optional)

**Business goal.** Stand up the entire mono-repo skeleton so feature work has a home. No product features — just the structure, tooling, local dev environment, CI, and the conventions made real in code.

**What it unlocks.** Every other epic. After this, `make up` runs the full stack locally and any agent can scaffold a feature into a known structure.

**Definition of done.**
- Mono-repo created per `02_project_structure.md` (`apps/`, `services/`, `infra/`, `packages/`, `docs/`).
- `docker-compose` brings up Postgres + Redis + API + (stub) admin.
- Django API boots with health-check `GET /healthz` → `{status: ok}`.
- Flutter app boots to a placeholder screen on Android + iOS.
- Next.js admin boots to a placeholder login.
- `Makefile` works: `up`, `down`, `migrate`, `test`, `lint`, `status`, `next`, `review-queue`.
- CI (GitHub Actions) runs lint + type + test on PR for each app.
- Pre-commit hooks installed (ruff, dart format, eslint/prettier).
- Shared design tokens package created from the Notun Din palette.
- `.env.example` complete; `DECISIONS.md` started; tracker scripts (`make status/next`) parse task frontmatter.

---

# PHASE: MVP

## EPIC-01 · Onboarding & Authentication
**Phase:** MVP · **Est. tasks:** ~12 · **Depends on:** EPIC-00
**External services:** WhatsApp Business API (OTP delivery) — *stub/console in dev until approved*; SMS gateway (fallback)

**Business goal.** Let a new user open the app, understand what Khatir is via 3 intro slides, and sign up with phone + OTP. No passwords.

**What it unlocks.** Every authenticated experience. The front door.

**Definition of done.**
- 3 intro slides (welcome / DMP wedge / free hook), Bangla default, skippable, re-accessible from More.
- `POST /auth/request-otp` + `POST /auth/verify-otp` + `POST /auth/refresh`; OTP in Redis, 6-digit, 5-min TTL, hashed, attempt-limited.
- Dev mode logs OTP to console (no real send needed to build).
- JWT access + refresh; Flutter stores tokens securely; dio interceptor attaches + refreshes.
- Tests: happy login, wrong OTP, expired OTP, refresh.

---

## EPIC-02 · Role & Profile Management
**Phase:** MVP · **Est. tasks:** ~8 · **Depends on:** EPIC-01
**External services:** none

**Business goal.** After first OTP, the user picks their role (Landlord default, Manager, Tenant). The app then routes them into the correct role shell. Basic profile + language toggle.

**What it unlocks.** Role-based navigation — the three distinct app experiences share one codebase.

**Definition of done.**
- Role chooser screen per the mobile UI; sets `User.role`.
- Three role shells (landlord/manager/tenant) with role-specific bottom nav, wired in go_router with redirect guards.
- Profile screen: name, language (bn/en) toggle that re-renders the app.
- Wrong-role access bounces to own shell.

---

## EPIC-03 · Properties & Units
**Phase:** MVP · **Est. tasks:** ~14 · **Depends on:** EPIC-02
**External services:** OpenStreetMap tiles (free, no key)

**Business goal.** Let a landlord build their portfolio: create buildings via the 3-step wizard (name+area → address → optional map pin) and add units to them.

**What it unlocks.** Everything tenant/lease/rent-related needs a unit to attach to.

**Definition of done.**
- Building CRUD + 3-step add wizard; address required, map pin optional (flutter_map + OSM).
- Unit CRUD; occupied/vacant/maintenance status.
- Portfolio list across buildings.
- `for_user` scoping enforced (landlord sees only own).
- Tests incl. cross-user isolation (404 for others' buildings).

---

## EPIC-04 · Tenant Management & NID OCR
**Phase:** MVP · **Est. tasks:** ~16 · **Depends on:** EPIC-03
**External services:** OCR provider (Google Cloud Vision or chosen) — via direct integration now, moves behind AI gateway in EPIC-14

**Business goal.** Register a tenant under a unit, capturing identity from an NID photo (OCR) or Bangla voice, with manual fallback. Store NID data encrypted.

**What it unlocks.** The DMP form (EPIC-05) and leases (EPIC-06). This is the data spine.

**Definition of done.**
- Add tenant: method chooser (photo / voice / manual).
- `POST /tenants/ocr` extracts fields from NID image; image stored encrypted; result editable.
- Voice fill path (Bangla ASR) producing the same structured fields.
- Tenant + family members persisted; NID encrypted + masked.
- Free-tier hook present (count toward the 2-tenant free limit — enforcement wired with EPIC-10).
- Audit on tenant create. Tests incl. encryption + masking.

---

## EPIC-05 · DMP Form Generation ★ (the wedge)
**Phase:** MVP · **Est. tasks:** ~10 · **Depends on:** EPIC-04
**External services:** none (PDF generated server-side)

**Business goal.** Generate the print-ready DMP (police) tenant-registration PDF from a tenant's data. This is the single feature that drives adoption.

**What it unlocks.** The core value proposition — "police form, from home, in 2 minutes." Ship-worthy on its own.

**Definition of done.**
- DMP form preview screen rendering all fields.
- `POST /dmpforms/{id}/pdf` produces a print-accurate PDF (field parity with the official template — **template must be field-verified before coding**).
- PDF stored, returned as signed URL, shareable via WhatsApp.
- `DMPFormRecord` persisted with template version.
- Tests: PDF generated, correct fields, free-tier accessible.

---

## EPIC-06 · Lease & Rent Schedule
**Phase:** MVP · **Est. tasks:** ~10 · **Depends on:** EPIC-04
**External services:** none

**Business goal.** Create a lease tying unit + tenant + landlord with rent/advance/dates, and auto-generate the monthly rent schedule.

**What it unlocks.** Rent collection (EPIC-07) and expenses linkage.

**Definition of done.**
- Lease CRUD; status lifecycle (draft→active→ended/terminated).
- On activation, RentSchedule rows auto-created (period, due_day, amount).
- Background job (Celery Beat) advances schedules monthly.
- Tests: schedule generation, due-date resolution, status transitions.

---

## EPIC-07 · Rent Collection (Web-Link) ★
**Phase:** MVP · **Est. tasks:** ~14 · **Depends on:** EPIC-06
**External services:** WhatsApp Business API + SMS fallback

**Business goal.** Landlord sends a rent request; tenant pays and submits proof via a no-install web link; landlord verifies; receipt generated. The signature differentiator.

**What it unlocks.** The recurring-use loop that retains landlords.

**Definition of done.**
- `RentRequest` create (scheduled + manual one-off); per-tenant signed `link_token`.
- WhatsApp message with web-link; SMS fallback.
- Tenant web page (`/r/{token}`, Django template, no auth) to submit `PaymentProof` (bkash txn / screenshot / photo / note).
- Landlord verify flow → `Payment` + auto receipt PDF sent back.
- Direct "mark received" (cash) bypass.
- Reminder cadence (24h/48h, from `SystemConfig`) via Celery.
- Tests incl. token scoping (one token = one request), proof submission, verification, receipt.

---

## EPIC-08 · Maintenance & Expense Tracker
**Phase:** MVP · **Est. tasks:** ~12 · **Depends on:** EPIC-06
**External services:** none

**Business goal.** Tenants report repairs; landlords resolve with a cost that becomes an expense; landlords also log expenses directly. Everything rolls into reporting.

**What it unlocks.** Dashboard expense data and tax-time value.

**Definition of done.**
- `MaintenanceRequest` (tenant submits category+desc+photo); landlord queue.
- Resolve-with-cost → auto `Expense` (source=request).
- Manual expense entry (source=manual).
- Expense list per building/unit; CSV export.
- Tests: request→resolve→expense chain, manual expense.

---

## EPIC-09 · Dashboard & Visualizations
**Phase:** MVP · **Est. tasks:** ~10 · **Depends on:** EPIC-07, EPIC-08
**External services:** none

**Business goal.** Give landlords an at-a-glance view: income, collection rate, occupancy, expense breakdown, late payers.

**What it unlocks.** The "open it daily" habit; perceived value.

**Definition of done.**
- Summary tiles (buildings, units, collected, pending).
- Collection-rate chart (6 mo), occupancy donut, income-vs-expense, top expense categories (fl_chart).
- Late-payers list with quick rent-request action.
- Aggregation endpoints performant (indexed); tests on the math.

---

## EPIC-10 · Pricing Tiers & Free Limit
**Phase:** MVP · **Est. tasks:** ~9 · **Depends on:** EPIC-04
**External services:** MFS billing (bKash/Nagad) — *can stub; real billing can trail slightly*

**Business goal.** Implement the 6 admin-configurable pricing tiers and enforce the free-tier rule (first 2 tenants free, no NID verification).

**What it unlocks.** Monetization + the free-tier growth hook.

**Definition of done.**
- `PricingTier` + `Subscription` models, seeded with the 6 tiers (values from DB, not hardcoded).
- Tenant-count metering; free-tier enforcement (2 tenants, verification gated).
- Upgrade prompt when limit reached.
- Tier values read from DB so EPIC-12 admin can change them.
- Tests: metering, free-limit gate, tier resolution.

---

## EPIC-11 · Admin Portal Foundation
**Phase:** MVP · **Est. tasks:** ~12 · **Depends on:** EPIC-00
**External services:** none (TOTP MFA is local)

**Business goal.** Stand up the Next.js admin portal: separate `AdminUser` auth with MFA, the dashboard shell, sidebar nav, and the audit-log plumbing every other admin module uses.

**What it unlocks.** All admin modules (12–16). Can be built in parallel with the mobile MVP once EPIC-00 is done.

**Definition of done.**
- `AdminUser` model (separate from User), email+password+TOTP MFA login.
- Dashboard shell (sidebar + topbar) per admin spec; auth guard; session timeout.
- Platform KPI dashboard (counts, activity feed, health, alerts).
- `AdminAuditEntry` infra + a generic audit-log viewer.
- Role-based admin access (super/ops/finance/compliance/support).
- Tests: MFA login, session expiry, role gating.

---

## EPIC-12 · Admin · Pricing & Users
**Phase:** MVP · **Est. tasks:** ~10 · **Depends on:** EPIC-10, EPIC-11
**External services:** none

**Business goal.** Let staff edit pricing tiers live (with impact preview) and manage user accounts (search, view, suspend, refund).

**What it unlocks.** Running the business without redeploys; support operations.

**Definition of done.**
- Pricing tier editor with live impact preview + reason + audit + rollout option; change live <60s.
- User search (phone/name/masked-NID/ID), detail view, suspend/reactivate/refund with reason + audit.
- Subscriptions table, refund queue.
- Tests: tier edit reflected in client config; user suspend audited.

---

## EPIC-13 · Admin · Feature Flags & Kill-Switch
**Phase:** MVP · **Est. tasks:** ~8 · **Depends on:** EPIC-11
**External services:** none

**Business goal.** Toggle features on/off without deploys, and provide the emergency kill-switch panel for reputation/free-text/public features.

**What it unlocks.** Safe rollout + the legal safety valve required before any reputation feature ships.

**Definition of done.**
- `FeatureFlag` CRUD + toggle console; clients read flags from `/config/public`.
- Kill-switch panel (warnings, reviews, history, free-text, master) with reason + MFA + audit.
- Toggling reflected across clients <60s.
- Tests: flag toggle hides feature; kill-switch disables instantly.

---

## EPIC-14 · Admin · AI Providers (+ AI Gateway service)
**Phase:** MVP · **Est. tasks:** ~12 · **Depends on:** EPIC-11
**External services:** the AI vendors themselves (OpenAI/Anthropic/Gemini/OpenRouter/Verbex/Google STT/Whisper/Google Vision/Azure/AWS/Tesseract)

**Business goal.** Stand up the FastAPI **AI gateway** microservice and the admin UI to configure providers (chat/voice/ocr/lease) with primary+fallback, API keys, test-connection, and usage tracking — swappable with no code change.

**What it unlocks.** Cost control + resilience; retro-fits EPIC-04 OCR behind the gateway.

**Definition of done.**
- `services/ai-gateway` (FastAPI) with provider abstraction, primary→fallback, usage logging.
- Backend `aiproxy` client calls the gateway.
- Admin UI: 4 category tabs, provider select, model, encrypted API key, endpoint, test-connection, usage panel.
- NID-OCR DPA constraint enforced at save.
- EPIC-04's OCR re-routed through the gateway.
- Tests: provider swap, failover, DPA gate.

---

## EPIC-15 · Admin · Notifications
**Phase:** MVP · **Est. tasks:** ~14 · **Depends on:** EPIC-11
**External services:** WhatsApp Business API, SMS gateway, email provider

**Business goal.** Let staff compose and send targeted, multi-channel, bilingual notifications, with history/tracking and reusable system templates.

**What it unlocks.** Marketing, transactional messaging (rent reminders, receipts, welcome), and the rent-collection messages EPIC-07 relies on (templates).

**Definition of done.**
- Composer: audience targeting (all/role/segment/specific), channels (inapp/whatsapp/sms/email), bilingual title+body, variables, schedule (now/scheduled/recurring), reach+cost preview.
- Delivery engine (Celery) + per-recipient `NotificationDelivery` tracking.
- History tab + templates tab (auto-triggered system templates editable).
- Tests: audience resolution, send, delivery tracking.

---

## EPIC-16 · Admin · Audit & Compliance
**Phase:** MVP · **Est. tasks:** ~9 · **Depends on:** EPIC-11
**External services:** none

**Business goal.** The compliance console: full audit-log search/export, consent records, verification logs, and data export/delete requests (PDPA-ready).

**What it unlocks.** Legal defensibility and the compliance posture required to operate.

**Definition of done.**
- Audit-log viewer with filters + CSV export.
- Consent records browser; verification logs (result only, never raw payload).
- Data export/delete request queue with SLA tracking.
- Tests: audit filter/export, data-request lifecycle.

> **═══ MVP COMPLETE at end of EPIC-16. The product is shippable to landlords. ═══**

---

# PHASE 1 (post-MVP monetize & harden)

## EPIC-17 · NID Verification (EC API)
**Phase:** P1 · **Est. tasks:** ~10 · **Depends on:** EPIC-04 (+14 gateway pattern)
**External services:** Election Commission "Matched/Not Matched" API

**Business goal.** Real identity verification against the EC. Paid tiers only; free tier excluded.

**Done when:** consent flow → EC check → matched/not-matched stored (never raw payload), metered per tier, graceful failure, audited.

## EPIC-18 · AI Lease Generation
**Phase:** P1 · **Est. tasks:** ~10 · **Depends on:** EPIC-06, EPIC-14
**External services:** LLM via AI gateway

**Business goal.** Generate DNCC-2025-compliant bilingual lease agreements; flag rule violations; e-sign.

**Done when:** lease generated from lease data, compliance lint, e-signature, per-doc fee, audited.

## EPIC-19 · Tenant App Features
**Phase:** P1 · **Est. tasks:** ~14 · **Depends on:** EPIC-07
**External services:** none new

**Business goal.** The tenant-side experience: self-register, link to lease, view receipts/lease, request maintenance, build a good-tenant record.

**Done when:** tenant can pair to a lease, see receipts, pay rent in-app, request maintenance; tenant home shell complete.

## EPIC-20 · Private Warnings
**Phase:** P1 · **Est. tasks:** ~10 · **Depends on:** EPIC-06, EPIC-13
**External services:** none — **requires written legal opinion before shipping**

**Business goal.** Private, factual landlord→tenant warnings, visible only to that pair, with right of reply and a kill-switch.

**Done when:** warning issue + reply, strictly private, audited, kill-switchable, behind a feature flag.

## EPIC-21 · Mutual Reviews
**Phase:** P1 · **Est. tasks:** ~10 · **Depends on:** EPIC-19
**External services:** none — legal-gated

**Business goal.** Reviews between consenting app users only, visible solely to that landlord–tenant pair.

**Done when:** both-app-user gate, structured + bounded text, right of reply, private visibility, kill-switchable.

## EPIC-22 · B2B Manager Tier
**Phase:** P1 · **Est. tasks:** ~12 · **Depends on:** EPIC-03
**External services:** none

**Business goal.** Activate the manager experience: manage multiple owners' portfolios, team seats, consolidated reporting.

**Done when:** `ManagerOwnerLink`/`TeamMember` fully used, owner switcher, aggregate reports, role permissions.

## EPIC-23 · AI Support Chatbot
**Phase:** P1 · **Est. tasks:** ~8 · **Depends on:** EPIC-14
**External services:** LLM via AI gateway

**Business goal.** Bangla chatbot for tenancy-law questions; routes complex issues to humans.

**Done when:** chatbot answers from a curated knowledge base, escalation path, usage tracked.

---

# PHASE 2 (reputation & gatekeeper)

## EPIC-24 · History Flags
**Phase:** P2 · **Est. tasks:** ~12 · **Depends on:** EPIC-20
**External services:** none — legal-gated, consent-gated

**Business goal.** Structured factual lease-outcome flags, consent-gated viewing by other verified landlords, AI factual summary from verified data only.

**Done when:** flags tied to completed verified leases, tenant notified + right of reply, per-request consent, view audit, kill-switchable.

## EPIC-25 · Gatekeeper / Caretaker
**Phase:** P2 · **Est. tasks:** ~14 · **Depends on:** EPIC-03
**External services:** none

**Business goal.** Building gate visitor logging: per-building QR, visitor web form, caretaker admit/refuse, 90-day retention.

**Done when:** caretaker role + scoping, QR → visitor web form → caretaker review → visitor log, optional tenant approval.

---

# PHASE 3 (optional government collaboration)

## EPIC-26 · Government Export
**Phase:** P3 · **Est. tasks:** ~6 · **Depends on:** EPIC-16
**External services:** DMP/DNCC (negotiated)

**Business goal.** Consented, scoped CIMS-compatible export feed for government partners.

**Done when:** scoped export, consent-gated, audited, no data leaves without consent.

---

## Summary table

| # | Epic | Phase | Est. tasks | Depends on | Key external svc |
|---|------|-------|-----------|------------|------------------|
| 00 | Foundation & Scaffold | — | 16 | — | — |
| 01 | Onboarding & Auth | MVP | 12 | 00 | WhatsApp/SMS |
| 02 | Role & Profile | MVP | 8 | 01 | — |
| 03 | Properties & Units | MVP | 14 | 02 | OSM |
| 04 | Tenants & NID OCR | MVP | 16 | 03 | OCR |
| 05 | DMP Form ★ | MVP | 10 | 04 | — |
| 06 | Lease & Rent Schedule | MVP | 10 | 04 | — |
| 07 | Rent Collection ★ | MVP | 14 | 06 | WhatsApp/SMS |
| 08 | Maintenance & Expenses | MVP | 12 | 06 | — |
| 09 | Dashboard | MVP | 10 | 07,08 | — |
| 10 | Pricing & Free Limit | MVP | 9 | 04 | MFS |
| 11 | Admin Foundation | MVP | 12 | 00 | — |
| 12 | Admin · Pricing & Users | MVP | 10 | 10,11 | — |
| 13 | Admin · Flags & Kill-switch | MVP | 8 | 11 | — |
| 14 | Admin · AI Providers (+gateway) | MVP | 12 | 11 | AI vendors |
| 15 | Admin · Notifications | MVP | 14 | 11 | WhatsApp/SMS/email |
| 16 | Admin · Audit & Compliance | MVP | 9 | 11 | — |
| 17 | NID Verification | P1 | 10 | 04 | EC API |
| 18 | AI Lease Gen | P1 | 10 | 06,14 | LLM |
| 19 | Tenant App | P1 | 14 | 07 | — |
| 20 | Private Warnings | P1 | 10 | 06,13 | (legal) |
| 21 | Mutual Reviews | P1 | 10 | 19 | (legal) |
| 22 | B2B Manager Tier | P1 | 12 | 03 | — |
| 23 | AI Chatbot | P1 | 8 | 14 | LLM |
| 24 | History Flags | P2 | 12 | 20 | (legal) |
| 25 | Gatekeeper | P2 | 14 | 03 | — |
| 26 | Government Export | P3 | 6 | 16 | DMP/DNCC |

**Totals:** 26 epics · ~282 tasks · MVP = epics 00–16 (~196 tasks).

---

## Parallelization notes (for multi-agent execution)

Once EPIC-00 is `verified`, two tracks can run in parallel:
- **Mobile/product track:** 01 → 02 → 03 → 04 → {05, 06} → {07, 08} → 09 → 10.
- **Admin track:** 11 → {12 (also needs 10), 13, 14, 15, 16}.

The only cross-track dependency inside MVP is EPIC-12 needing EPIC-10. So the admin portal foundation and most admin modules can be built by a separate agent stream while the mobile MVP proceeds — they converge when pricing (10) meets the pricing admin (12), and when feature flags (13) and notifications (15) start backing mobile features.

**External-service long-poles to start early (parallel to coding):**
- WhatsApp Business API approval (2–3 weeks) — start at EPIC-00.
- EC NID API access paperwork — start now, needed for EPIC-17 (P1).
- MFS (bKash/Nagad) merchant onboarding — needed for real billing in EPIC-10.
- Written legal opinion on warnings/reviews/history — **blocks EPIC-20, 21, 24.**
- Official DMP form template field-verification — **blocks EPIC-05.**
