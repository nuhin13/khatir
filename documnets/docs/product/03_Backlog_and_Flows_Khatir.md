# Feature Backlog & User Flows — Khatir (খাতির)
**Version:** 1.0 (Final · post-rebrand)
**Companion docs:** `01_BRD_Khatir.md`, `02_SRS_Khatir.md`, `04_Admin_Portal_Khatir.md`

---

## How to read this doc

- Stories are sized in **T-shirt** (XS = ~2 days, S = ~1 week, M = ~2 weeks, L = ~4 weeks, XL = ~8+ weeks) for a team of 3–4 engineers.
- **Priority:** P0 = must-have at launch · P1 = within 18 months · P2 = year 2–3 · P3 = optional future.
- Each epic ends with **acceptance** (Definition of Done) and **dependencies**.

---

# Part 1 — Phase 0 / MVP Backlog (M0–6)

The MVP must let a 50-year-old landlord, in Bangla, on a mid-range Android, do the full workflow shown in SRS §8.

---

## EPIC 0 — Foundation (M0–1)

| # | Story | Size |
|---|-------|------|
| 0.1 | Project scaffold (Django+DRF, PostgreSQL 15+, Redis, Celery, Celery Beat) | S |
| 0.2 | React 18 PWA shell with Vite, Bangla-first, language toggle, service worker | S |
| 0.3 | Auth: phone + OTP via WhatsApp Business API + SMS fallback | M |
| 0.4 | User & role model (landlord/manager/tenant/caretaker/admin) | S |
| 0.5 | Audit-log + encryption-at-rest infra | M |
| 0.6 | Observability (Sentry, structured logs, metrics) | S |
| 0.7 | Brand identity setup: design tokens, fonts, theme variables | XS |

**Acceptance:** dev environment runs locally; phone+OTP works on Android Chrome and iOS Safari; every write to user-personal data lands in audit log; design tokens (sage/rose/butter/cream/ink) wired into theme.

---

## EPIC 1 — Intro & First-Launch & Role Chooser (M1)

| # | Story | Size |
|---|-------|------|
| 1.1 | 3 intro slides (welcome / DMP wedge / free hook) | S |
| 1.2 | Slides accessible later from More → About Khatir | XS |
| 1.3 | A/B switch on slide order (admin flag) | XS |
| 1.4 | **Role chooser screen** after OTP — Landlord (default) / Manager / Tenant cards with per-role perks | S |
| 1.5 | **Role-based home routing** — Landlord home / Manager portfolio home / Tenant lease home | M |
| 1.6 | Role-change option in More menu | XS |

**Acceptance:** first-time install shows 3 slides → OTP → role chooser → role-specific home; landlord is default; analytic events fire per role pick.

---

## EPIC 2 — Property & Unit Management (M1–2)

| # | Story | Size |
|---|-------|------|
| 2.1 | **Add Building wizard — Step 1:** building name + area dropdown (10 Dhaka areas) | S |
| 2.2 | **Add Building wizard — Step 2:** full address textarea (required, used in DMP form) | S |
| 2.3 | **Add Building wizard — Step 3:** optional map pin with Leaflet+OSM (tap-to-place, drag, reset, skip) | M |
| 2.4 | CRUD Unit (label, type, rent, amenities, status) | S |
| 2.5 | Mark occupied / vacant / under-maintenance | XS |
| 2.6 | Portfolio listing across buildings (collapsed cards) | S |
| 2.7 | **Manager: multi-owner switcher** — pill-based owner selection on home screen, scoped data per owner | M |
| 2.8 | **Manager: aggregate "all owners" view** with combined stats | S |

**Acceptance:** landlord completes the 3-step wizard for 2 buildings + 14 units in <5 min; map pin opt-in works; manager can switch between 3 owner portfolios in <2 taps.

---

## EPIC 3 — Tenant Onboarding + DMP Form (M1–3) ★ Wedge

| # | Story | Size |
|---|-------|------|
| 3.1 | Add tenant under a unit (basic form) | S |
| 3.2 | **NID OCR** — upload/photo + AI extraction (name, NID, DOB, address) | L |
| 3.3 | **Bangla voice fill** — record → ASR → LLM extract → structured fields | L |
| 3.4 | Family-member & home-staff sub-records | M |
| 3.5 | **DMP form PDF generator** — exact field parity with official form | L |
| 3.6 | DMP CTA prominent on home dashboard | XS |
| 3.7 | Encrypted document storage per tenant (NID image, PDF) | M |

**Acceptance:** from a single NID photo, system produces a print-ready DMP PDF in <60s; voice fallback works end-to-end; storage encrypted.

**Risk:** field-verify the current DMP form template before locking in.

---

## EPIC 4 — Rent Request & Collection (M2–4) ★ Signature feature

| # | Story | Size |
|---|-------|------|
| 4.1 | RentSchedule model + monthly auto-creation on lease | M |
| 4.2 | Manual one-off rent request creation | S |
| 4.3 | WhatsApp Business API integration (template messages) | M |
| 4.4 | SMS fallback for non-WhatsApp users | S |
| 4.5 | **Tenant web link** (no install) — minimal one-screen page | L |
| 4.6 | Payment proof submission: txn ID, screenshot, photo, note | M |
| 4.7 | Landlord notification: "X says paid · Verify" | S |
| 4.8 | Verification screen with image preview + Receive / Not yet received | M |
| 4.9 | Auto-generated receipt PDF on confirmation | M |
| 4.10 | Reminder cadence engine (24h, 48h, admin-configurable) | M |
| 4.11 | Direct mark "Received" (cash collected in person) bypass | S |
| 4.12 | Late-payer flag on dashboard | XS |
| 4.13 | In-app equivalent flow for app-using tenants | M |

**Acceptance:** landlord can send a request to 5 tenants in <30s; tenant on a phone with no install gets WhatsApp link, opens it, submits a bKash screenshot, and receives a receipt PDF after landlord verifies — all in <3 min.

---

## EPIC 5 — Expense & Maintenance Tracker (M3–4)

| # | Story | Size |
|---|-------|------|
| 5.1 | Tenant submits maintenance request (app or web link): category + description + photo | M |
| 5.2 | Landlord request queue (per-unit grouping) | S |
| 5.3 | Resolve with cost + date + receipt photo | M |
| 5.4 | Manual expense entry (no request) | S |
| 5.5 | Category taxonomy (plumbing/paint/electrical/structural/appliance/utility/other) | XS |
| 5.6 | Expense list view per building / per unit | S |
| 5.7 | Export expenses CSV (for tax) | S |

**Acceptance:** end-to-end tenant request → landlord resolves with Tk 18,500 cost → expense appears in dashboard's top-categories card.

---

## EPIC 6 — Dashboard & Charts (M3–5)

| # | Story | Size |
|---|-------|------|
| 6.1 | Summary tiles (buildings, units, collected, pending) | S |
| 6.2 | **Collection-rate chart** — last 6 months (Recharts) | M |
| 6.3 | **Occupancy donut** (occupied / vacant / pending) | S |
| 6.4 | **Income vs expense** monthly comparison | M |
| 6.5 | **Top expense categories** breakdown with progress bars | S |
| 6.6 | Late payers list | XS |
| 6.7 | DMP CTA banner (re-emphasis) | XS |
| 6.8 | Optional map view of buildings with pins | M |

**Acceptance:** dashboard loads in <2s on mid-range Android; all 5 chart cards render with real data.

---

## EPIC 7 — Pricing, Free Tier & Billing (M4–6)

| # | Story | Size |
|---|-------|------|
| 7.1 | PricingTier data model (admin-configurable) | S |
| 7.2 | Tenant-count metering (active tenants on leases) | S |
| 7.3 | **Free-tier enforcement** — first 2 tenants free, no NID verification | M |
| 7.4 | Per-tenant tier (3–10 tenants) | M |
| 7.5 | Bundle 20 / Bundle 40 tiers | S |
| 7.6 | Unlimited monthly (Tk 1,299 cap) | S |
| 7.7 | Unlimited annual (Tk 999/mo with 12-mo commit) | M |
| 7.8 | bKash/Nagad subscription billing | L |
| 7.9 | In-app upgrade prompt when free limit reached | S |
| 7.10 | Invoice PDFs + payment history | S |

**Acceptance:** prices are read from DB; admin can change any tier from the admin portal without redeploy; free-tier landlord with 2 tenants gets full UX except NID verification.

---

## EPIC 8 — Admin Portal (M4–6)

Full spec in `04_Admin_Portal_Khatir.md`. Summary of P0 stories:

| # | Story | Size |
|---|-------|------|
| 8.1 | Admin auth with MFA (TOTP) | M |
| 8.2 | **Pricing config UI** — all tier breakpoints, prices, currencies | M |
| 8.3 | User / account search + suspend / refund | M |
| 8.4 | Audit-log viewer with filters | M |
| 8.5 | Feature-flag console (per role, per phase) | M |
| 8.6 | **Kill-switch panel** — disable any free-text or reputation feature instantly | M |
| 8.7 | Verification logs viewer (consent + result, never raw payload) | S |
| 8.8 | System config (reminder cadence, retention periods, etc.) | S |
| 8.9 | Dashboard with platform-wide metrics | M |
| 8.10 | Admin user management (create/disable/scope) | S |
| 8.11 | **AI Providers — Chat/LLM** config (OpenAI, Anthropic, OpenRouter, Gemini, self-hosted) with primary + fallback + test connection | L |
| 8.12 | **AI Providers — Voice/ASR** config (Verbex, Google STT, Whisper, Azure, self-hosted) | M |
| 8.13 | **AI Providers — OCR/Vision** config (Google Vision, Azure DI, AWS Textract, Tesseract) with NID-hosted constraint check | M |
| 8.14 | **AI Providers — Lease-gen** config (Anthropic, OpenAI, Gemini) | S |
| 8.15 | **AI Providers — usage tracking** (requests, tokens, cost, success rate, latency) per provider per category | M |
| 8.16 | **AI Providers — runtime failover** (primary fails → fallback → error, logged) | M |
| 8.17 | **Notifications — composer** (audience targeting, channels, bilingual body, variables, schedule) | L |
| 8.18 | **Notifications — audience segmentation** (role, segment, location, specific users) | M |
| 8.19 | **Notifications — multi-channel delivery** (in-app, WhatsApp, SMS, email) with cost preview | M |
| 8.20 | **Notifications — history & tracking** (sent/delivered/opened/cost per send) | M |
| 8.21 | **Notifications — system templates** (rent reminder, welcome, free-limit, etc. — auto-triggered, admin-editable) | M |
| 8.22 | **Notifications — scheduling** (immediate / scheduled / recurring) | M |

**Acceptance:** admin can change Free tier from 2 → 3 tenants and the change is reflected in clients on next refresh, with audit-logged change record. Admin can swap chatbot LLM from Claude to GPT-4o and verify with test-connection button. Admin can send a notification to all free-tier landlords with ≥2 tenants via WhatsApp + in-app, see reach/cost preview, and track delivery.

---

## EPIC 9 — Foundational Compliance & Legal (M5–6, ongoing)

| # | Story | Size |
|---|-------|------|
| 9.1 | BD-hosted infra setup (NDC-compatible or equivalent) | L |
| 9.2 | Data-minimization policy enforcement (store result, mask raw) | M |
| 9.3 | Consent capture UI + immutable log | M |
| 9.4 | Privacy policy + ToS (Bangla + English) | S |
| 9.5 | Breach-notification runbook (72hr) | S |
| 9.6 | Lawyer-signoff gate before any reputation/warning feature ships | — |

**Acceptance:** lawyer has signed off on data flows; consent capture has full audit trail; no NID-touching code runs outside BD-hosted infra.

---

## MVP exit criteria

A landlord can:
1. View 3 intro slides
2. Sign up via phone+OTP (Bangla)
3. **Pick role: Landlord / Manager / Tenant**
4. **Add buildings via 3-step wizard** (name + area → address → optional map pin) + units
5. Add a tenant via NID OCR **or** voice **or** manual
6. Generate a print-ready DMP form PDF
7. Set up a monthly rent schedule
8. Send a rent request → tenant submits proof on web link → landlord verifies → receipt
9. Log a maintenance request and resolve with cost
10. See dashboard with 5 charts + late-payers list
11. Stay free with ≤2 tenants (full UX except verification)

A manager can additionally:
12. Switch between multiple owner portfolios via pill picker

A tenant can additionally:
13. View lease, pay rent (via web link), request maintenance, see receipts

…and an admin can:
14. Log in with MFA, change pricing tiers, toggle features, view audit log
15. **Swap AI providers** (Chat/LLM, Voice, OCR, Lease-gen) with primary + fallback + test connection
16. **Send notifications** to targeted audience segments via multiple channels with reach/cost preview

…all without any public listing or review surface anywhere.

---

# Part 2 — Phase 1 Backlog (M6–18)

Monetize and harden.

| Epic | Story | Size |
|------|-------|------|
| 10 — NID verification | EC "Matched/Not Matched" API + consent + binary result + face match | XL |
| 10.1 | Verification credits per tier + metered overage | M |
| 10.2 | Graceful failure UX | S |
| 11 — AI lease | DNCC-2025-compliant lease generator (Bangla+English) | L |
| 11.1 | E-signature integration | L |
| 11.2 | Lease template versioning | S |
| 12 — Tenant app (optional) | Self-registration + pair to lease | M |
| 12.1 | Receipts, lease, rent history view | S |
| 12.2 | Maintenance request from app | S |
| 12.3 | "Good tenant" record (private, app-only) | M |
| 13 — Mutual reviews | Reviews between consenting app users only | M |
| 13.1 | Structured + bounded free-text, with right of reply | M |
| 13.2 | Visibility limited to that landlord–tenant pair | S |
| 14 — Complaints & warnings | Landlord → tenant private warning | L |
| 14.1 | Right of reply per warning | S |
| 14.2 | Audit log + kill switch | S |
| 15 — B2B Manager Tier | Manager portfolio model + role permissions | L |
| 15.1 | Consolidated reporting across owners | M |
| 15.2 | Team-member seats | S |
| 16 — Support chatbot | Bangla AI chatbot for tenancy-law Qs | M |
| 17 — Notifications hub | In-app + WhatsApp + SMS preferences | S |
| 18 — Hardening | Performance, load testing, observability deepening | M |

---

# Part 3 — Phase 2 Backlog (M18–36)

Reputation + gatekeeper.

| Epic | Story | Size |
|------|-------|------|
| 19 — History flags | Structured factual flags tied to completed leases | L |
| 19.1 | Tenant notification + right-of-reply on every flag | M |
| 19.2 | Consent-gated viewing (paying landlords only, per-request) | M |
| 19.3 | AI factual summary from verified flag data only | M |
| 19.4 | View audit log + tenant-side visibility | S |
| 20 — Gatekeeper / Caretaker | Caretaker account + scoping to building | M |
| 20.1 | Per-building unique QR (printed at gate) | S |
| 20.2 | Visitor web form (no install) | M |
| 20.3 | Caretaker review/admit screen | S |
| 20.4 | Visitor log (search, 90-day retention default) | M |
| 20.5 | Optional destination-tenant approval before admission | M |
| 21 — Tenant good-record portfolio | Aggregate cross-lease record (consented) | M |
| 22 — Building network effects | Multi-landlord building dynamics, shared caretaker | M |

---

# Part 4 — Phase 3 Backlog (M36+)

| Epic | Story | Size |
|------|-------|------|
| 23 — Gov export | Scoped CIMS-compatible export feed (consent-gated) | L |
| 24 — Open API for managers | B2B API for large estate managers | L |

---

# Part 5 — Critical User Flows

## Flow A — First-time landlord onboarding
1. Install / open PWA → **3 intro slides** (welcome / DMP wedge / free hook).
2. "Start free" → phone + OTP (WhatsApp).
3. **Role chooser screen** — pick Landlord (default chip), Manager, or Tenant. Per-role perks shown.
4. Role = Landlord → minimal profile (name + area).
5. Home dashboard appears with **DMP form CTA as the headline card** and "Free 0/2 tenants" indicator.

## Flow A2 — First-time manager onboarding
1. Same intro + OTP as Flow A.
2. Role chooser → pick Manager.
3. Add first property owner (name + phone) → link.
4. Manager home appears with aggregate portfolio header and owner switcher pills.

## Flow A3 — First-time tenant onboarding
1. Same intro + OTP as Flow A.
2. Role chooser → pick Tenant.
3. Link to existing lease via landlord invite or pairing code.
4. Tenant home appears with current rent due, lease info, recent receipts.

## Flow B — Add building (3-step wizard)
1. Landlord home → quick action "🏢 বিল্ডিং যোগ".
2. **Step 1:** enter building name (e.g., "Karim Manzil") + pick area chip (e.g., "Mirpur").
3. **Step 2:** enter full multi-line address (used in DMP form).
4. **Step 3 (optional):** map opens; tap to place pin or skip. Pin draggable. Reset clears it.
5. Save → returns to home; building appears in portfolio.

## Flow C — Tenant onboarding via NID OCR ★ wedge
1. Tap DMP CTA → Method chooser (Photo / Voice / Manual).
2. Choose Photo → camera frame opens → capture NID.
3. AI extracts fields → review screen (edit if needed).
4. Continue → DMP form preview (full PDF-like rendering).
5. "Download PDF" → file saved + WhatsApp share option.

## Flow D — Tenant onboarding via voice
1. Tap DMP CTA → Method chooser → Voice.
2. Big mic button → press & speak.
3. Transcript shown + structured fields extracted.
4. Confirm → DMP form preview → PDF.

## Flow E — Rent request ★ signature flow
1. Home → quick action "ভাড়া চান".
2. List of tenants with unit + amount; pick recipients (default = all).
3. Send. Backend creates RentRequest per tenant.
4. WhatsApp message with **unique web link**.
5. Tenant taps link → minimal page with amount/period/landlord; "পেমেন্ট প্রমাণ আপলোড".
6. Tenant uploads bKash screenshot OR enters txn ID OR adds note → Submit.
7. Landlord receives notification: "Karim says paid ৳22,000 · Verify".
8. Landlord opens, sees image + details, taps "টাকা পেয়েছি" (Received).
9. System generates receipt PDF; sends back to tenant.
10. If not verified in 24h → nudge to landlord. 48h → second nudge.
11. Alternate: landlord directly marks "Received" without tenant action.

## Flow F — Maintenance request → expense
1. Tenant submits: category + description + photo.
2. Landlord queue shows it under that unit.
3. Landlord taps → "Resolve with cost" → enters amount + date + optional receipt.
4. Expense auto-created; dashboard top-categories updates.
5. Tenant sees status "Resolved".

## Flow G — NID verification (paid tiers)
1. From tenant detail → "NID যাচাই করুন".
2. Consent screen ("EC service · Matched/Not Matched · ৳75").
3. Tenant consent confirmed.
4. Submit → loading → result: Matched (✓) or Not Matched (✗).
5. Result stored; raw payload not stored.
6. If on free tier with 2 tenants already → upgrade prompt instead.

## Flow H — Dashboard daily check
1. Home → tap "ড্যাশবোর্ড".
2. Top: total income card (৳5L+, ↑12%).
3. Collection rate chart (last 6 months).
4. Occupancy donut (11/14, 78%).
5. Top expense categories.
6. Tap any chart → drill-in (deferred to P1).

## Flow I — Manager: switch portfolio
1. Manager home shows aggregate stats across all owners.
2. Owner switcher pills in horizontal scroll — tap an owner's pill.
3. Home re-scopes: quick actions, buildings, rent, expenses now show *that owner's* data only.
4. Aggregate banner remains pinned at top to show overall portfolio context.

## Flow J — Complaint / warning (P1)
1. From lease detail → "Warning issue করুন" → category dropdown.
2. Brief factual note (with character limit + lint warning if subjective).
3. Submit → tenant gets notification.
4. Tenant can attach reply.
5. Visibility: **only** this lease's pair. Audit-logged.

## Flow K — Gatekeeper QR (P2)
1. Visitor at gate scans printed QR.
2. Phone opens web form: name, phone, dest flat, dest person, purpose, selfie.
3. Caretaker app pings.
4. Caretaker calls tenant; admits or refuses → log entry.
5. Optional: caretaker setting requires tenant in-app approval first.

## Flow L — Admin: change pricing (P0)
1. Admin logs in via MFA.
2. Navigates to Pricing & Tiers.
3. Edits Free tier from 2 → 3 tenants.
4. Sees impact preview ("X landlords will be affected").
5. Confirms → audit log entry created, change live within 60s.

## Flow M — Admin: kill-switch (P1+)
1. Legal flags concern with warnings feature.
2. Admin logs in → Kill-Switch Panel.
3. Toggles "Warnings" to OFF.
4. Confirms with reason + lawyer reference.
5. All warning-related UI immediately hidden across all clients on next refresh. Audit logged.

## Flow N — Admin: swap AI provider (P0)
1. Chatbot response quality is degrading — admin investigates.
2. Admin opens AI Providers → Chat/LLM tab.
3. Sees current = Anthropic Claude (sonnet-4-7), fallback = OpenAI.
4. Selects OpenAI as primary, GPT-4o model.
5. Pastes API key (masked) → clicks "Test connection" → green checkmark.
6. Sets fallback to Anthropic.
7. Save → audit-logged → change takes effect within 60s → next chatbot request uses GPT-4o.

## Flow O — Admin: send broadcast notification (P0)
1. Marketing wants to promote new AI lease feature to all paying landlords.
2. Admin opens Notifications → Compose.
3. Audience = By segment → "paying landlords" (312 users).
4. Channels = In-app + WhatsApp.
5. Composes bilingual title + body, using `{name}` template variable.
6. Sees preview (WhatsApp bubble) on right.
7. Sees summary: 312 recipients, ~৳156 cost, immediate.
8. Schedule = Immediately → Send.
9. Admin sees real-time delivery progress; full delivery report in History tab.

---

# Part 6 — Cross-cutting design rules

- **Bangla-first.** English secondary, never primary.
- **40–65yo accessibility.** Big tap targets, large readable type, voice + OCR everywhere manual entry exists.
- **Low-bandwidth tolerance.** Web link pages must work on 3G, <2s load.
- **Offline drafts.** All forms (tenant, expense, maintenance) save draft locally if no connection.
- **No public anything.** No listing pages, no public reviews. Reputation/warnings always private + factual + consent-gated.
- **Admin-configurable everything that touches money.** Pricing, tier breakpoints, verification fees, lease fees.
- **Kill-switches everywhere reputation/warnings/free-text live.** Admin must be able to disable instantly.
- **Brand consistency.** Khatir lockup with descriptor on every external surface for first 12 months.

---

# Part 7 — Out of scope (kept as explicit decisions)

- Public listing marketplace
- Public reviews of identifiable people
- Government NID database scraping or any non-EC NID lookup
- Managed-rental / property-management operations
- Payment fund custody / escrow
- Open-text reputation fields
- Cross-landlord warnings visible without consent

These should be revisited only with new legal guidance and only if data shows the current model is insufficient.
