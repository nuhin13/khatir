# Software Requirements Specification (SRS)
## Khatir (খাতির) — Landlord Compliance & Verified-Rental Platform

**Version:** 1.0 (Final · post-rebrand)
**Companion docs:** `01_BRD_Khatir.md`, `03_Backlog_and_Flows_Khatir.md`, `04_Admin_Portal_Khatir.md`

---

## 1. Introduction

### 1.1 Purpose
This SRS translates the BRD into engineering requirements. It is the contract between product and engineering and the primary input for Claude Code.

### 1.2 Scope of this document
- **Landlord App (PWA, mobile-first)** — primary surface, Bangla-first.
- **Tenant App (optional PWA)** — receipts, requests, mutual reviews.
- **Tenant Web Link (no install)** — rent payment confirmation flow.
- **Caretaker App (Phase 2)** — gatekeeper QR module.

> Admin Portal requirements are detailed in `04_Admin_Portal_Khatir.md`.

### 1.3 Definitions
- **CIMS / DMP form** — DMP Citizen Information / Tenant Registration Form.
- **EC API** — Election Commission "Matched/Not Matched" NID verification.
- **MFS** — Mobile Financial Services (bKash, Nagad).
- **Rent request** — landlord-initiated request for tenant to pay (scheduled or manual).
- **Payment proof** — tenant-submitted evidence (bKash screenshot, transaction ID, photo).
- **History flag** — structured factual lease-tied reputation entry (Phase 2).
- **Warning** — private landlord→tenant in-conversation notice. Never public.

### 1.4 Recommended stack
- **Backend:** Django + DRF, PostgreSQL 15+, Redis, Celery, Celery Beat.
- **Frontend (landlord/tenant/caretaker):** React 18 PWA, Vite build, mobile-first, offline-tolerant via service worker.
- **Frontend (admin portal):** React 18, Vite, desktop-first, role-based.
- **AI:** hosted vision OCR + Bangla ASR + LLM; BD/on-prem for NID-touching data.
- **Maps:** Leaflet + OpenStreetMap (free, no Google Maps API cost) for optional address pin.
- **Charts:** Recharts (lightweight, React-native, mobile-friendly).
- **Infra:** BD-hosted (NDC-compatible), Docker, GitHub Actions CI/CD. Encrypted object storage (S3-compatible).
- **Messaging:** WhatsApp Business API (primary); SMS gateway (fallback).
- **Auth:** Phone+OTP (no passwords); JWT with refresh tokens; admin portal MFA-required.

### 1.5 Brand and visual identity
- **Aesthetic:** "Notun Din" — sage green (#7BA084), dusty rose (#E89B8B), butter yellow (#F4D58D), warm cream (#FBF6EE), ink (#2C3530).
- **Fonts:** Plus Jakarta Sans (titles), Caveat (handwritten accents), Hind Siliguri (Bangla body).
- **Logo lockup:** "Khatir · বাড়িওয়ালার ডিজিটাল খাতা" (mandatory for first 12 months).
- **Border radius:** generous (16–24px on cards, 999px on buttons).
- **Shadows:** soft, low-opacity (e.g., `0 4px 14px -8px rgba(80,60,40,.12)`).

---

## 2. Overall Description

### 2.1 User classes
| Class | Access | Key needs |
|-------|--------|-----------|
| Landlord | Full self-serve via mobile PWA | Paperwork, rent collection, expenses, dashboards, history |
| Building Manager (B2B) | Multi-property roles | Portfolio ledgers, team access |
| Tenant — App | Limited (mobile PWA) | Profile, receipts, requests, mutual reviews |
| Tenant — Web Link | One-time per action (no account) | Payment proof submission, view receipts |
| Caretaker (P2) | Single building scope (mobile PWA) | QR scan, visitor log |
| Admin (internal) | Backoffice via web portal | Pricing/tiers, support, moderation, compliance |
| Gov partner (P3) | Scoped export | CIMS-compatible feed (consented) |

### 2.2 Operating environment
- **Primary:** Android mobile browsers (PWA). iOS Safari supported.
- **Low-bandwidth tolerant:** core flows work on 3G; web links load <2s on 3G.
- **Bangla default, English toggle.**
- **Admin portal:** desktop Chrome/Edge/Safari/Firefox latest 2 versions.

### 2.3 Hard product constraints
- No public listing pages.
- No public review pages.
- No open-text reputation fields, ever.
- Warnings are private to the specific landlord–tenant pair, logged, with right of reply.
- All NID-derived data encrypted, BD-hosted, minimal storage.

---

## 3. Functional Requirements

### 3.1 Onboarding (P0)
- **FR-1.1** First-launch flow shows **3 intro slides**: (a) what Khatir is, (b) the wedge — "DMP form, 2 min", (c) the free hook — "First 2 tenants free, no verification needed."
- **FR-1.2** Slides are skippable but always accessible from More → "About Khatir."
- **FR-1.3** Slides localized Bangla (default) + English.
- **FR-1.4** **Role chooser** after OTP verification. User picks one: **Landlord** (default · recommended chip), **Building Manager** (B2B), or **Tenant**. Each role surfaces a different home dashboard. Role is changeable later from More menu.
- **FR-1.5** **Role-based home routing.** Landlord → property/tenant management home. Manager → multi-owner portfolio home (owner switcher pills + aggregate stats). Tenant → lease/pay-rent/maintenance home.

### 3.2 Authentication & Accounts (P0)
- **FR-2.1** Phone + OTP (WhatsApp primary, SMS fallback).
- **FR-2.2** Role selection: Landlord / Manager / Tenant / Caretaker.
- **FR-2.3** Profile management; Bangla/English toggle.
- **FR-2.4** Session management with refresh tokens; logout from all devices option.
- **FR-2.5** **Manager-specific:** can be linked to multiple property-owner accounts (one-to-many), with team-member sub-seats.

### 3.3 Property & Unit Management (P0)
- **FR-3.1** Create Buildings via 3-step wizard:
    - **Step 1** — Building name (required) + Area dropdown (required: Uttara, Mirpur, Mohammadpur, Dhanmondi, Banasree, Gulshan, Banani, Bashundhara, Old Dhaka, Other).
    - **Step 2** — Full address (required, multi-line textarea, used in DMP form).
    - **Step 3** — **Optional map pin** (Leaflet + OSM, tap-to-place, draggable, skip allowed).
- **FR-3.2** Map pin stores lat/lng; default null. User can tap anywhere on map to place; tap again to move; reset button clears it.
- **FR-3.3** Create Units under a building (label, type, rent, amenities, availability).
- **FR-3.4** Edit/archive; mark occupied/vacant/under-maintenance.
- **FR-3.5** Portfolio view across all buildings owned by a landlord.
- **FR-3.6** **For Managers:** portfolio view scoped to *currently-selected owner*, plus aggregate "all owners" view.

### 3.4 Tenant Onboarding & DMP Form (P0 — wedge)
- **FR-4.1** Add tenant under a unit.
- **FR-4.2** **NID OCR** — photograph card; AI extracts fields; confirm/edit.
- **FR-4.3** **Bangla voice fill** — voice note → structured fields.
- **FR-4.4** System pre-fills DMP form (landlord + tenant + unit + family + home-staff sub-records).
- **FR-4.5** Export DMP form as print-ready PDF (exact field parity with official form).
- **FR-4.6** **DMP form CTA is visually prominent on the home dashboard.**
- **FR-4.7** Encrypted document storage per tenant.

### 3.5 Identity Verification (P1)
- **FR-5.1** "Verify" action → EC "Matched/Not Matched" API with consent.
- **FR-5.2** Display binary result; optional face match.
- **FR-5.3** Record verification status + timestamp (store result, not raw payload).
- **FR-5.4** **Free tier limit:** verification disabled for the 2 free tenants.
- **FR-5.5** Charge per check (metered) for users above free tier without bundled credits.
- **FR-5.6** Graceful failure if API unavailable; never block onboarding.

### 3.6 Rent Request & Collection (P0/P1) — signature feature

Core insight: **tenants don't need to install the app.**

- **FR-6.1** **Rent schedule.** On lease creation, system auto-creates a monthly rent schedule (amount, due day).
- **FR-6.2** **Manual rent request.** Landlord can also create one-off requests anytime.
- **FR-6.3** **Tenant notification.** On schedule trigger / manual request:
    - If tenant has the app → in-app notification + WhatsApp push.
    - If no app → WhatsApp message + SMS fallback with a **unique web link** (no install required).
- **FR-6.4** **Tenant payment-proof flow (web link).** The web link opens a one-screen page where the tenant can: view amount/period/landlord; pay via own MFS externally; upload **payment proof** (bKash transaction ID, screenshot, photo, written note); submit.
- **FR-6.5** **Landlord verification step.** Landlord receives notification ("Karim says he paid ৳22,000 — verify"). Landlord taps **Received** → cycle closes; receipt PDF auto-generated and sent to tenant link/app.
- **FR-6.6** **Reminder cadence.** If landlord doesn't verify within 24h, system nudges. After 48h, second nudge. Configurable from admin portal.
- **FR-6.7** **Pending state.** If tenant said paid but landlord hasn't confirmed, status = "Pending verification." Landlord can mark "Not yet received" → tenant gets a follow-up.
- **FR-6.8** **Direct manual mark.** Landlord can also just mark a rent as Received without any tenant action (cash collected in person).
- **FR-6.9** **In-app tenant flow.** If tenant has the app, identical flow happens in-app (no link, just notifications).
- **FR-6.10** **Receipts.** Receipt PDF auto-generated on confirmation; delivered via WhatsApp link + in-app.
- **FR-6.11** **Late-payer flags.** Dashboard shows red indicators for overdue.

### 3.7 Tenant App / Tenant Web (P0/P1)
- **FR-7.1** **Tenant self-registration.** Tenants can register (phone + OTP) and link to existing leases by accepting a landlord invite or pairing code.
- **FR-7.2** **Tenant features (app):** view leases, receipts, submit payment proofs, request maintenance, review landlord (P1+, app users only).
- **FR-7.3** **Tenant web link only:** payment-proof submission per request; view receipt PDFs. No account, no persistence.

### 3.8 Lease / Agreement (P1)
- **FR-8.1** **AI lease generator** — DNCC-2025-compliant rent agreement in Bangla + English.
- **FR-8.2** Rules engine flags clauses violating 2-year rent-hike rule or advance caps.
- **FR-8.3** E-signature for both parties.
- **FR-8.4** Per-document fee (or included in higher tiers).

### 3.9 Expense & Maintenance Tracker (P0/P1)
- **FR-9.1** **Tenant request.** Tenant (app or web link via WhatsApp) submits a maintenance request: category (electrical/plumbing/paint/other), description, optional photo.
- **FR-9.2** **Landlord queue.** Landlord sees requests per unit in a dedicated tab.
- **FR-9.3** **Resolve with cost.** Landlord marks request resolved with: cost, resolution date, optional notes/receipt photo.
- **FR-9.4** **Expense ledger.** Auto-recorded per-flat expense entry. Visible in dashboard and tax report.
- **FR-9.5** **Manual expense.** Landlord can add expenses directly (not tied to a request).
- **FR-9.6** **Categories.** Painting, plumbing, electrical, structural, appliance, utility, other.

### 3.10 Complaints & Warnings (P1, strict rules)
- **FR-10.1** Landlord can issue a **private warning** to a tenant: structured category (late payment, noise, damage, other) + brief factual description.
- **FR-10.2** Warning is visible **only** to landlord and that tenant. Never public, never to other landlords (until lease completion → may convert to factual flag in P2 with consent).
- **FR-10.3** Tenant has right of reply on each warning.
- **FR-10.4** Warning history visible only on that lease's record.
- **FR-10.5** Audit log of all warnings + replies.
- **FR-10.6** Kill-switch (from admin portal) can disable warnings instantly if legal advice changes.

### 3.11 Dashboard & Visualizations (P0)
- **FR-11.1** **Summary cards:** total buildings, units, monthly rent due, monthly collected.
- **FR-11.2** **Occupancy donut chart** by building / overall.
- **FR-11.3** **Collection rate bar chart** last 6 months.
- **FR-11.4** **Income vs expense** monthly comparison.
- **FR-11.5** **Top expense categories** breakdown with progress bars.
- **FR-11.6** **Late payers list** with quick action to send rent request.
- **FR-11.7** **DMP form CTA prominently displayed** on home screen.
- **FR-11.8** **Optional map view** of all buildings with pins.

### 3.12 B2B Manager Tier (P1)
- **FR-12.1** Manager account managing multiple owners' portfolios.
- **FR-12.2** Role-based permissions (owner, manager, staff).
- **FR-12.3** Consolidated reporting across portfolio.

### 3.13 Mutual Reviews (P1, app users only)
- **FR-13.1** After lease completion (or any time during, by mutual consent), landlord can review tenant *and* tenant can review landlord.
- **FR-13.2** Reviews are **only available if both parties are app users** (tenant must have installed app).
- **FR-13.3** Structured + free-text within constrained categories — but **only visible between that landlord and that tenant** until Phase 2 history feature opens it with consent.
- **FR-13.4** Right of reply.

### 3.14 Private History / Reputation Graph (P2)
- **FR-14.1** History flag created **only** against verified, completed lease on platform.
- **FR-14.2** **Structured factual flags only** (enumerated): rent_on_time, lease_completed, dispute=yes/no + factual note. No subjective adjectives.
- **FR-14.3** Tenant notified of any flag; may attach right-of-reply.
- **FR-14.4** Visible **only** to other verified, paying landlords, with tenant's **per-request explicit consent**.
- **FR-14.5** **AI factual summary** generated strictly from verified flag data; never infers protected attributes; no "good/bad" verdicts.
- **FR-14.6** Audit log of all views (tenants can see who viewed their record).

### 3.15 Gatekeeper / Caretaker Module (P2)
- **FR-15.1** **Caretaker account.** Building gatekeeper signs up with role "Caretaker" (or is invited by landlord); scoped to specific buildings.
- **FR-15.2** **Visitor QR.** Each building has a unique QR code (printed at gate). Unknown visitor scans → opens a web form (no install).
- **FR-15.3** **Visitor form.** Visitor provides: name, phone, NID number (optional), destination flat, person to meet, purpose, photo of self.
- **FR-15.4** **Caretaker confirmation.** Caretaker reviews on app; calls/messages the destination tenant; admits or refuses.
- **FR-15.5** **Visitor log.** Stored per-building. Searchable.
- **FR-15.6** **Optional landlord verification.** Landlord can require approval from destination tenant before admission.
- **FR-15.7** **Caretaker is free** — building-wide adoption is the goal, not caretaker monetization.
- **FR-15.8** **Privacy.** Visitor data retained 90 days by default (configurable from admin portal); auto-purged after.

### 3.16 AI Support Chatbot (P1)
- **FR-16.1** Bangla chatbot for tenancy-law questions (advance limits, rent controller process, DNCC rules).
- **FR-16.2** Routes complex issues to human support.

### 3.17 Government Export (P3 — optional)
- **FR-17.1** Consented, scoped CIMS-compatible export for DMP/DNCC.

### 3.18 AI Provider Configuration (P0, admin-managed)
- **FR-18.1** All AI providers (Chat/LLM, Voice/ASR, OCR/Vision, Lease-gen) are **admin-configurable** from the admin portal — no code changes required to swap providers.
- **FR-18.2** **Supported categories and providers** (extensible):
    - **Chat/LLM** (chatbot, summaries, lease-gen): OpenAI, Anthropic Claude, OpenRouter, Google Gemini, self-hosted (Ollama).
    - **Voice/ASR** (Bangla voice tenant onboarding, voice chatbot): Verbex, Google Speech-to-Text, OpenAI Whisper, Azure Speech, self-hosted Whisper.
    - **OCR/Vision** (NID extraction): Google Cloud Vision, Azure Document Intelligence, AWS Textract, self-hosted Tesseract.
    - **Lease-gen** (DNCC-compliant rental agreements): Anthropic Claude, OpenAI, Google Gemini.
- **FR-18.3** **Per category, admin configures:**
    - Primary provider + model selection (dropdown from supported models for that provider).
    - Fallback provider chain (primary fails → fallback → error).
    - API key (encrypted at rest, masked in UI, copyable).
    - Endpoint URL (for self-hosted only).
    - Temperature, max tokens, other model parameters where applicable.
- **FR-18.4** **Test connection** button per provider — issues a minimal test call to verify credentials and connectivity before saving.
- **FR-18.5** **Usage tracking** per category, per provider: request count, token/minute count, cost, success rate, average latency (last 30 days).
- **FR-18.6** **Provider failover** at runtime: if primary fails (timeout, 5xx, rate limit), system automatically falls back to configured fallback provider and logs the failover event.
- **FR-18.7** **NID-touching OCR constraint:** OCR provider used for NID extraction must be either BD-hosted or covered by a signed Data Processing Agreement. Admin portal enforces this at save-time with a warning if the selected provider doesn't meet the requirement.
- **FR-18.8** **Custom endpoint support:** admin can add a custom OpenAI-compatible endpoint (e.g., self-hosted Ollama, alternative providers exposing OpenAI-compatible APIs).
- **FR-18.9** Provider changes take effect within 60 seconds across all clients and are audit-logged (admin user, before/after, timestamp).

### 3.19 Admin Notifications & Broadcasts (P0/P1, admin-initiated)
- **FR-19.1** Admins (with appropriate role) can compose and send notifications to end users from the admin portal.
- **FR-19.2** **Audience targeting:**
    - **All users** — entire platform.
    - **By role** — checkbox multi-select: Landlord, Manager, Tenant, Caretaker.
    - **By segment** — pre-built segments: paying landlords, free-tier landlords, free-tier landlords with ≥2 tenants (upgrade candidates), inactive landlords (30d+), past-due subscribers, landlords by location (area dropdown), landlords by building count.
    - **Specific users** — search and select individual user IDs.
- **FR-19.3** **Channels** (multi-select per notification):
    - **In-app** notification (free) — appears in user's notification bell.
    - **WhatsApp** (cost ৳0.5/msg, illustrative) — via WhatsApp Business API templates.
    - **SMS** (cost ৳0.3/msg, illustrative) — fallback for non-WhatsApp users.
    - **Email** (free) — for users with email on file.
- **FR-19.4** **Bilingual composition:** title (EN) + title (BN) + body (EN) + body (BN). Tenant/landlord sees the version matching their language preference.
- **FR-19.5** **Template variables:** `{name}`, `{unit}`, `{tier}`, `{rent_amount}`, `{building_name}` — auto-substituted per recipient.
- **FR-19.6** **Scheduling:**
    - **Immediate** — send now.
    - **Scheduled** — send at specific datetime.
    - **Recurring** — daily/weekly/monthly cadence with end condition.
- **FR-19.7** **Reach + cost estimate** computed before send; admin must confirm.
- **FR-19.8** **System-generated templates** (auto-triggered, admin-editable): rent reminder (1st/2nd), welcome new landlord, free-tier limit reached, payment received, maintenance resolved, subscription expiring 7d, NID verification result.
- **FR-19.9** **History & delivery tracking:** every notification logged with sent_at, audience, channels, recipients_sent, recipients_delivered, recipients_opened, status. Searchable, filterable, exportable to CSV.
- **FR-19.10** **Compliance:** every admin-initiated notification audit-logged with sender admin user, full content, audience criteria, and confirmation. No PII in notification logs beyond user IDs.
- **FR-19.11** **Tenant opt-out** respected for promotional notifications. Transactional notifications (rent due, receipt, security) are always sent.

---

## 4. Non-Functional Requirements

### 4.1 Security & Privacy
- **NFR-1.1** All NID/personal data encrypted at rest (AES-256), in transit (TLS 1.2+).
- **NFR-1.2** BD-hosted / NDC-compatible for NID-touching data.
- **NFR-1.3** Data minimization: store result not raw payloads; mask NID where possible.
- **NFR-1.4** Consent capture logged immutably.
- **NFR-1.5** 72-hour breach notification capability (PDPA-ready).
- **NFR-1.6** RBAC across all consoles.
- **NFR-1.7** Full audit trail on verification, reviews, warnings, history views, visitor logs.
- **NFR-1.8** Admin portal: MFA required for all admin accounts.

### 4.2 Performance
- **NFR-2.1** Core screens interactive <3s on 3G mid-range Android.
- **NFR-2.2** OCR <10s; voice structuring <15s.
- **NFR-2.3** Web rent-link loads <2s on 3G (lightweight).
- **NFR-2.4** Support 50k concurrent at Phase 2.
- **NFR-2.5** Admin portal pages <1.5s on broadband.

### 4.3 Usability
- **NFR-3.1** Bangla-first; English toggle.
- **NFR-3.2** Mobile-first landlord/tenant/caretaker apps; large tap targets (40–65yo users).
- **NFR-3.3** Voice + OCR everywhere manual entry is required.
- **NFR-3.4** Offline draft + sync.

### 4.4 Reliability
- **NFR-4.1** 99.5% uptime (P1+).
- **NFR-4.2** Verification/messaging failures degrade gracefully; never block core paperwork.
- **NFR-4.3** Daily encrypted backups; tested restore.

### 4.5 Compliance
- **NFR-5.1** No feature may produce public reviews or open accusations about identifiable people.
- **NFR-5.2** Reputation, warnings, history all behind feature flags + legal sign-off.
- **NFR-5.3** PDPA + Cyber Security Ordinance review each release touching personal data.

### 4.6 Localization & Accessibility
- **NFR-6.1** Bangla (default) / English. Bangla numerals option.
- **NFR-6.2** WCAG AA contrast; screen-reader labels on key actions.

---

## 5. Data Model (logical)

Core entities:

- **User** (id, phone, role [landlord/manager/tenant/caretaker/admin], name, lang, created_at)
- **AdminUser** (id, email, mfa_secret, scope[], role, last_login_at) — separate from User
- **Building** (id, owner_user_id, name, address, area, lat?, lng?)
- **Unit** (id, building_id, label, type, rent, amenities[], status, available_from)
- **Tenant** (id, name, nid_number_masked, dob, address, photo_ref, verification_status, verified_at, is_app_user, linked_user_id?)
- **TenantFamilyMember** (id, tenant_id, name, relation)
- **Lease** (id, unit_id, tenant_id, landlord_user_id, start, end, rent, advance, status, signed_pdf_ref)
- **RentSchedule** (id, lease_id, period, due_date, amount, status, sent_at)
- **RentRequest** (id, rent_schedule_id?, lease_id, amount, period, link_token, sent_via, sent_at, status [sent/proof_submitted/verified/rejected])
- **PaymentProof** (id, rent_request_id, type [bkash_txn/screenshot/photo/note], value, photo_ref, submitted_at)
- **Payment** (id, rent_request_id, verified_at, verified_by, receipt_ref)
- **MaintenanceRequest** (id, unit_id, lease_id?, category, description, photo_ref?, status, created_at, resolved_at?, resolution_cost?, resolution_note?)
- **Expense** (id, unit_id, category, amount, date, source [request/manual], note, receipt_ref?)
- **Warning** (id, lease_id, category, factual_note, issued_at, replied_at?, reply_note?)
- **Review** (id, lease_id, by_user_id, target_user_id, structured_data, note, visibility [private_pair])
- **DMPFormRecord** (id, tenant_id, unit_id, generated_pdf_ref, exported_at)
- **VerificationLog** (id, tenant_id, result, requested_by, consent_ref, created_at)
- **HistoryFlag** (id, lease_id, flag_type, factual_note) — P2
- **RightOfReply** (id, parent_type [flag/warning/review], parent_id, statement)
- **ConsentRecord** (id, subject_tenant_id, purpose, granted_by, scope, expires_at)
- **AuditEntry** (id, actor_user_id, action, target_ref, created_at, ip, user_agent)
- **VisitorLog** (id, building_id, name, phone, photo_ref, dest_flat, dest_person, purpose, scan_at, admitted_at?, admitted_by_user_id?) — P2
- **PricingTier** (id, key, label, label_bn, tenant_min, tenant_max, monthly_price, annual_price, includes_verification, included_credits, active, sort_order)
- **Subscription** (id, user_id, tier_id, start_at, billing_cycle, status, next_billing_at)
- **FeatureFlag** (id, key, description, scope [global/role/user], enabled, value_json)
- **SystemConfig** (id, key, value, type, description) — for admin-managed settings
- **AIProvider** (id, category [chat/voice/ocr/lease], provider_key [openai/anthropic/openrouter/gemini/verbex/google_stt/whisper/azure_stt/google_vision/azure_ocr/aws_textract/tesseract/local], is_primary, is_fallback, model_name, api_key_encrypted, endpoint_url?, params_json, active)
- **AIUsageLog** (id, provider_id, category, request_count, tokens_used, cost_usd, success, latency_ms, created_at, failover_from_provider_id?)
- **ManagerOwnerLink** (id, manager_user_id, owner_user_id, permissions[], created_at) — manager-to-landlord relationship
- **TeamMember** (id, manager_user_id, member_user_id, role [accountant/assistant/viewer], scope_owner_ids[])
- **Notification** (id, admin_user_id?, system_trigger?, audience_type, audience_filter_json, channels[], title_en, title_bn, body_en, body_bn, scheduled_at?, sent_at?, status, recipient_count, delivered_count, opened_count, cost_bdt)
- **NotificationDelivery** (id, notification_id, recipient_user_id, channel, status, delivered_at?, opened_at?, error?)
- **NotificationTemplate** (id, key, title_en, title_bn, body_en, body_bn, trigger_event, channels[], variables[], active)

---

## 6. External Integrations

| Integration | Phase | Purpose |
|-------------|-------|---------|
| EC "Matched/Not Matched" API | P1 | NID verification |
| WhatsApp Business API | P0 | Notifications, web-link delivery |
| SMS gateway | P0 | Fallback for non-WhatsApp users |
| MFS (bKash/Nagad) | P1+ | Subscription billing |
| AI Vision OCR | P0 | NID extraction |
| Bangla ASR + LLM | P0+ | Voice fill, lease gen, summaries, chatbot |
| Maps (OSM/Leaflet) | P0 | Optional building address pin |
| e-Sign provider | P1 | Lease signatures |
| Recharts | P0 | Dashboard visualizations |

---

## 7. Constraints & Assumptions

- **C-1** Founder owns tech team (~3–4 engineers).
- **C-2** EC API access for startups **unconfirmed** — Phase 1 verification depends on it; OCR-only + free-tier fallback exists.
- **C-3** CIMS 2026 status **unconfirmed** — wedge messaging may need repositioning.
- **C-4** No fund custody until licensing clarity.
- **C-5** All reputation/warning work blocked until written legal opinion obtained.
- **C-6** Pricing must be admin-configurable from day one (no hard-coded prices).
- **C-7** Brand identity locked: Khatir name, Notun Din aesthetic, dual-script lockup for 12 months.

---

## 8. Acceptance Criteria (MVP / Phase 0)

The MVP is accepted when a landlord can, on a mobile phone, in Bangla:
1. See 3 intro slides on first launch explaining product + free hook.
2. Sign up with phone + OTP.
3. **Pick role: Landlord (default) / Manager / Tenant.**
4. **Add a building via the 3-step wizard:** name + area → full address → optional map pin.
5. Add units under that building.
6. Add a tenant via NID OCR **or** Bangla voice note.
7. Generate and export a print-ready DMP form PDF.
8. Create a rent schedule for the tenant.
9. Send a rent request → tenant receives WhatsApp link → submits payment proof on web (no install).
10. Verify the proof → receive a generated receipt.
11. Log a maintenance request (as tenant) and resolve it with a cost (as landlord).
12. See dashboard with occupancy donut, collection-rate chart, and income/expense breakdown.
13. Stay free if managing ≤2 tenants — full workflow works, no verification.

A **manager** can additionally:
14. See multi-owner portfolio with owner switcher and aggregate stats.
15. Switch between owners to manage their respective buildings.

A **tenant** can additionally:
16. View lease info, pay rent, request maintenance, see receipts.

…and an admin can:
17. Log in to the admin portal via MFA.
18. Change Free-tier tenant limit from 2 to 3 without code change.
19. View audit log of any user's actions.
20. Disable the warnings feature via kill-switch.
21. **Swap the chatbot LLM from Claude to GPT-4o without redeploy** — change takes effect within 60s.
22. **Swap voice provider from Verbex to Whisper** with fallback configured.
23. **Send a notification to all free-tier landlords with ≥2 tenants** via WhatsApp + in-app with reach/cost preview.

All without any public listing or review surface anywhere.
