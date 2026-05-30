# Business Requirements Document (BRD)
## Khatir (খাতির) — Landlord Compliance & Verified-Rental Platform for Dhaka

**Version:** 1.0 (Final · post-rebrand)
**Date:** May 2026
**Status:** Confidential — Internal
**Owner:** Founder / Product Lead

> **Brand lockup:**
> **Khatir** · বাড়িওয়ালার ডিজিটাল খাতা
> *The landlord's digital ledger*

---

## 1. Document Purpose

This BRD defines *what* the business needs and *why*. It is the source of truth for scope, audience, monetization, team, and go-to-market. Technical specification lives in `02_SRS_Khatir.md`; the feature backlog and user flows live in `03_Backlog_and_Flows_Khatir.md`; the admin portal specification lives in `04_Admin_Portal_Khatir.md`.

---

## 2. Brand Identity

### 2.1 Name
**Khatir (খাতির)** — a Bangla word meaning *respectful care, hospitality, treating someone with dignity*. The product gives the landlord *khatir* (care for his property and tenants) and helps him give *khatir* to good tenants.

| Context | Form |
|---------|------|
| English content, international, App Store | **Khatir** |
| Bangla content, BD marketing | **খাতির** |
| Hybrid lockup (first 12 months) | **খাতির · Khatir** |

### 2.2 Taglines

| Surface | Tagline |
|---------|---------|
| **Logo descriptor** (permanent) | বাড়িওয়ালার ডিজিটাল খাতা · *The landlord's digital ledger* |
| **Launch hook** (ads, posters) | পুলিশ ফর্ম, ঘরে বসে ২ মিনিটে। · *Police form, from home, in 2 minutes.* |
| **Secondary hook** (after 6 mo) | ভাড়া চাইতে আর ফোন করতে হবে না। · *No more calling to ask for rent.* |
| **Homepage promise** | আপনার বাড়ির কাগজপত্র, ভাড়ার হিসাব, ভাড়াটিয়ার তথ্য — সব এক জায়গায়, নিরাপদে। · *Your property paperwork, rent ledger, and tenant records — together, securely.* |

### 2.3 Visual identity
- **Aesthetic direction:** "Notun Din" (নতুন দিন · New Day) — soft, friendly, warm. Sage green + dusty rose + warm cream, rounded everything, illustrated accents.
- **Why this aesthetic:** the target user (40–65yo Dhaka landlord) is intimidated by tech-startup minimalism but alienated by cluttered Indian super-app aesthetics. *Notun Din* feels like a trusted neighbor — least intimidating for first-time tech users while still feeling modern enough for younger family members.
- **Brand fonts:** Plus Jakarta Sans (titles), Caveat (handwritten accents), Hind Siliguri (Bangla body).
- **Logo descriptor lockup is mandatory** for the first 12 months — never let "Khatir" appear alone until brand recognition is established.

---

## 3. Executive Summary

Khatir is a **landlord-first SaaS** for Dhaka that digitizes the legally-mandated tenant paperwork every landlord already has to do, lets landlords collect and verify rent without forcing tenants to install anything, tracks per-flat expenses and maintenance, and — only later, privately — adds a factual rental-history signal.

It is deliberately **NOT** a public listings portal and **NOT** a public review site.

**Three things make this product work where others have failed:**
1. **Landlord-only adoption is sufficient.** Tenants use a web link, not an app. Reviews work only between consenting app users.
2. **The first 2 tenants are free** without NID verification — the entire core workflow is usable at zero cost, so adoption isn't gated on a payment decision.
3. **DMP form generation is the visible hook** — the single most universal pain point, placed front-and-center.

**Honest ceiling:** Profitable SME-scale business (~Tk 20–50 crore ARR by year 5), not a unicorn. Raise angel/pre-seed only.

> **Single most important product rule:** Never ship a public, open-text review system. Under the Cyber Security Ordinance 2025, online defamation carries fines up to Tk 25 lakh, no platform immunity. All reputation features are private, lease-tied, consent-gated, and factual.

---

## 4. Business Objectives

| # | Objective | Metric | Timeframe |
|---|-----------|--------|-----------|
| O1 | Default digital tool for Dhaka tenant paperwork | 5,000 landlord accounts | Month 6 |
| O2 | Prove willingness to pay (free tier converts) | 500+ paying landlords | Month 12 |
| O3 | Sustainable recurring revenue | Tk 24M ARR, <25% churn | Month 18 |
| O4 | Legally-safe private reputation + gatekeeper | 30% of leases carry flags; 50+ buildings on gatekeeper | Month 36 |
| O5 | Optional gov collaboration | 1 DMP/DNCC pilot | Month 36+ |

---

## 5. Problem Statement

A Dhaka multi-unit landlord lives with **seven** recurring frictions:

1. **Mandatory tenant registration (DMP form / CIMS)** — physical thana trips, re-filling fields per tenant. *(2026 functional status to be field-verified.)*
2. **Identity risk** — no way to confirm a prospective tenant is who they claim.
3. **Rent collection & reminders** — chasing tenants every month; no payment-proof workflow.
4. **Rent tracking & receipts** — notebooks across dozens of units.
5. **Tax & record-keeping** — messy income records; DNCC Jan 2025 guidelines (written agreements, 2-year rent-hike limits, advance caps) raise documentation pressure.
6. **Maintenance & expenses** — repair requests handled by phone calls, costs untracked, history lost.
7. **"Is this tenant trouble?"** — no structured memory after a bad tenant; no legal way to share.

Khatir solves 1–6 in MVP/Phase 1 and addresses 7 privately in Phase 2. **No listings, no public reviews.**

---

## 6. Scope

### 6.1 In Scope
- First-launch onboarding (3 intro slides + free-hook explanation)
- Landlord/property/unit/tenant data management
- DMP-form mirror with PDF export (visually highlighted)
- NID OCR + AI voice form-filling
- EC "Matched/Not Matched" identity verification (Phase 1)
- **Rent request flow** with auto-schedule, manual one-offs, and tenant payment-proof via web link (no app required)
- Per-flat **expense & maintenance tracker** (tenant requests → landlord resolves with cost + date)
- **Dashboard with charts** (occupancy, collection rate, monthly income, expense vs income)
- **Optional address pin on map** for buildings
- Tenant-app side (optional): receipts, requests, mutual reviews
- AI lease generation (DNCC-compliant)
- **Complaints & warnings** (private, landlord–tenant only, NEVER public)
- Private, consent-gated rental-history flags (Phase 2)
- **Gatekeeper / caretaker module** (Phase 2): QR-based visitor logging
- B2B building-manager tier
- **Admin portal** (web-based) for pricing/tier configuration, user management, compliance console, feature flags, kill-switches

### 6.2 Out of Scope (permanently or until proven)
- Public property listings marketplace
- Public, open-text reviews of identifiable people
- Government NID database scraping
- Managed-rental / property-management operations
- Payment custody/escrow at launch

---

## 7. Target Audience

| Segment | Profile | Role |
|---------|---------|------|
| **PRIMARY: Multi-unit landlord** | Owns 2–6 buildings / 15–40 units in Uttara, Mirpur, Mohammadpur, Banasree, Dhanmondi. Age 40–65. WhatsApp & bKash user. Hates paperwork, tax season, chasing rent. | **PAYER** |
| **SECONDARY: Building manager** | Manages portfolio for owners; needs ledgers, expense tracking, reports. | PAYER (B2B tier) |
| **TERTIARY: Tenant (optional app user)** | Salaried/freelancer in Tk 20–50k flats. Most use only the web link; power users install the app for receipts and good-tenant record. | LIGHT USER, occasional payer |
| **Phase 2: Caretaker / Darwan** | Building gatekeeper. Uses app for visitor QR logging. Adoption drives whole-building network effects. | LIGHT USER |
| **Phase 3: DMP / DNCC** | Government partners | Potential licensee |

---

## 8. Market Size (TAM → SAM → SOM)

| Layer | Definition | Estimate |
|-------|-----------|----------|
| TAM | All Dhaka rental households | ~1.5–1.75M rented units |
| Serviceable | Multi-unit landlords | ~120,000–200,000 |
| SAM | Smartphone-using landlords in target zones | ~60,000–90,000 |
| SOM (5-yr) | Realistically capturable paying | ~6,000–12,000 |

*Order-of-magnitude only; validate with field research before fundraising.*

### Revenue projection
| Year | Free accounts | Paying landlords | Blended ARPU/mo | Annual revenue |
|------|---------------|------------------|-----------------|----------------|
| 1 | 4,500 | 300 (≈6%) | Tk 400 | ~Tk 0.14 cr |
| 2 | 15,000 | 1,500 (≈10%) | Tk 550 | ~Tk 1.0 cr |
| 3 | 30,000 | 4,000 (≈13%) | Tk 700 | ~Tk 3.4 cr |
| 4 | 50,000 | 7,500 (≈15%) | Tk 850 | ~Tk 7.7 cr |
| 5 | 75,000 | 12,000 (≈16%) | Tk 950 | ~Tk 13.7 cr |

---

## 9. Monetization

### 9.1 The principle
**Free up to 2 tenants without NID verification.** This makes the entire core workflow (DMP form, OCR, voice, rent collection, expense tracking, dashboard) usable forever at zero cost for the smallest landlords. They become the marketing engine — referring other landlords, displaying "Khatir verified" stickers, building the brand.

### 9.2 Pricing tiers (admin-configurable from admin portal)

| Tier | Tenants covered | Includes | Monthly price |
|------|----------------|----------|---------------|
| **Free** | 1–2 tenants | All core features; **no NID verification** | Tk 0 |
| **Per-tenant** | 3–10 tenants | All features + verification credits | Tk 50/tenant/mo (illustrative; admin-set) |
| **Bundle 20** | 11–20 tenants | All features + bulk verification | Tk 599/mo (illustrative) |
| **Bundle 40** | 21–40 tenants | All features + B2B reporting | Tk 899/mo (illustrative) |
| **Unlimited Monthly** | Unlimited | All features | **Tk 1,299/mo** (cap) |
| **Unlimited Annual** | Unlimited, 12-month commit | All features | **Tk 999/mo** (effective; billed annually) |

**Key constraints:**
- All prices and tier breakpoints are configurable from the **admin portal** — no code change needed to adjust.
- Cap = Tk 999/mo with annual commit, Tk 1,299/mo without.
- Tenant count = active tenants on platform (occupied units with linked tenants).

### 9.3 Other revenue streams
| Stream | Price (illustrative, admin-configurable) |
|--------|------------------------------------------|
| NID verification | Tk 50–100/check (EC rail; per-tenant tiers include credits) |
| AI lease generation | Tk 300–1,000/doc (or included in higher tiers) |
| Tenant add-ons | Small/occasional |
| Gov license (P3) | Negotiated |

---

## 10. Phasing Overview

- **Phase 0 / MVP (M0–6) — Wedge & Trust.** DMP form + OCR + voice + rent request web-link + expense tracker + dashboard charts + admin portal. **Free for everyone** to start. Build trust, hit 5,000 accounts.
- **Phase 1 (M6–18) — Monetize.** NID verification (EC rail), AI lease, complaints/warnings (private), tenant app (optional), mutual reviews (between consenting app users only), B2B manager tier. Paywall the per-tenant tiers above 2.
- **Phase 2 (M18–36) — Reputation & Gatekeeper.** Consent-gated factual history flags; caretaker QR visitor module; tenant good-record portfolio.
- **Phase 3 (M36+) — Government Collaboration.** Optional CIMS-compatible partnership.

Detailed feature backlog: `03_Backlog_and_Flows_Khatir.md`. Admin portal specification: `04_Admin_Portal_Khatir.md`.

---

## 11. Team & Execution Plan (Non-Tech)

> Tech team is founder-owned. Assume ~3–4 engineers (1 backend, 1 frontend, 1 full-stack/DevOps, optional 1 mobile). Below is the **minimum non-tech team**.

### 11.1 Phase 0–1 minimum team (lean core)

| Role | Count | Why essential | When |
|------|-------|---------------|------|
| **Founder / CEO (you)** | 1 | Product, fundraising, tech oversight, landlord relationships | Day 1 |
| **Field Sales Lead** | 1 | The most important non-tech hire. Walks landlord associations, in-person demos. | Month 1 |
| **Field Sales Reps** | 2 | Zone-by-zone onboarding; hand-holding 40–65yo landlords. | Month 3 |
| **Customer Support / Onboarding (Bangla)** | 1 | WhatsApp-first support. Doubles as QA. | Month 2 |
| **Ops / Compliance & Legal liaison** | 1 (part-time retainer → FT by M9) | DMP-form accuracy, EC API paperwork, legal coordination. | Month 2 |
| **Content / Growth Marketer** | 1 | Bangla content, referral programs, landlord-association outreach. | Month 4 |

**Phase 0–1 non-tech: ~6 people** (you + 5) + ~3–4 engineers = **~9–10 total**.

### 11.2 Phase 2 additions

| Role | Count | Why |
|------|-------|-----|
| Sales Manager (promote from Lead) | — | Scale field team to 6–8 reps |
| Additional Field Reps | +3–4 | Wider zones |
| B2B Enterprise Account Manager | 1 | Sell manager tier to complexes & developers |
| Data Protection Officer | 1 | PDPA requirement once enacted |
| Finance / Billing Ops | 1 | Subscription billing, churn, tax |

**Phase 2 non-tech: ~12–14 people.**

### 11.3 Hiring principles
- Hire sellers before marketers.
- Bangla-native, locally-rooted reps.
- Legal on retainer early, FT only when reputation layer ships.
- Don't over-hire marketing in Phase 0 — nothing to scale yet.

---

## 12. Marketing Hooks

> The message is **never** "find a flat." Always paperwork pain, rent chasing, and tenant trust.

### 12.1 Primary hooks (landlord-facing)
1. **"পুলিশ ফর্ম, ঘরে বসে ২ মিনিটে।"** *(Police form, from home, in 2 minutes.)* — **the launch wedge.**
2. **"প্রথম ২ ভাড়াটিয়া সম্পূর্ণ ফ্রি।"** *(First 2 tenants completely free.)* — the free-hook trigger.
3. **"ভাড়া চাইতে আর ফোন করতে হবে না।"** *(No more phone calls to ask for rent.)* — the rent-request hook.
4. **"বাড়িওয়ালার ডিজিটাল খাতা।"** *(The landlord's digital ledger.)* — the brand line.
5. **"ট্যাক্সের সময় আর ঝামেলা নেই।"** *(No more headache at tax time.)*

### 12.2 Phase 2 hooks
6. **"ভাল ভাড়াটিয়ার রেকর্ড, খারাপ ভাড়াটিয়ার সতর্কতা।"** *(Record for good tenants, warning for bad ones.)*
7. **"আপনার বিল্ডিং সবচেয়ে সুরক্ষিত — Khatir Gatekeeper।"** *(Your building, safest — Khatir Gatekeeper.)*
8. **"খাতির রাখুন, ঝামেলা ছাড়ুন।"** *(Keep Khatir, leave the hassle.)* — brand-aware wordplay (only after brand equity).

### 12.3 Tenant-side hook
9. **"ভাল ভাড়াটিয়া হিসেবে রেকর্ড গড়ুন — পরের বাসা পান সহজে।"** *(Build your good-tenant record — get your next home faster.)*

### 12.4 Channel strategy
- **Landlord associations & building-owner societies** — clusters of the exact payer.
- **WhatsApp-first** onboarding, reminders, support.
- **Facebook to-let groups** — advertise the paperwork tool to landlords already there.
- **Referral program** — refer-a-landlord = 1 free month.
- **"Khatir verified" stickers** for buildings — physical trust signal + free advertising.

---

## 13. Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Landlords (older, less tech) won't adopt | High | Free tier kills payment friction; field-sales hand-holding; voice/Bangla UI |
| Tenants refuse to use web link to confirm rent | Medium | Manual fallback: landlord marks "received" directly; tenant link is optional confirmation |
| Public-review temptation creeps back in | Critical | Hard rule; legal sign-off gate on every reputation/warning string |
| EC NID API access denied to startup | High | Free tier covers 2 tenants without verification; OCR-only fallback |
| CIMS app quietly fixed by DMP | Medium | Field-verify before build; reposition around rent collection + expense if needed |
| Cyber Security Ordinance §29 complaint | Critical | No open text; warnings stay private; right of reply built-in |
| PDPA enacted with strict rules | Medium | Consent-gating, local hosting, DPO hire |
| Bikroy launches tenant verification | Medium | Deepen B2B + gatekeeper moat; the listings player won't replicate compliance + expenses + caretaker |
| Not venture-scale | Known | Raise angel/pre-seed; run for profitability |

---

## 14. Kill-Switches

- **<500 paying landlords by M12** → pivot to B2B compliance SaaS for developers/complex managers.
- **First §29 complaint against platform** → disable any open-text field instantly via admin portal kill-switch.
- **PDPA enacted with strict rules** → budget Tk 1–2 crore compliance or shut history feature.
- **Bikroy launches tenant verification** → deepen B2B + gatekeeper moat or pursue acquisition.

---

## 15. Pre-Build Verification (still required)

1. Is CIMS app functional in 2026? Field-verify before locking the wedge messaging.
2. Can a startup obtain EC "Matched/Not Matched" API access? Begin paperwork now; have a fallback if denied.
3. Pre-sell the concept to 20 landlords across target zones — get verbal commitments and price feedback.
4. Field-survey DNCC tenancy guideline awareness/enforcement among target landlords.
5. Obtain written legal opinion on the reputation, warning, and private history flag designs before any related code ships.
