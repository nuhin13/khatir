# 00 · System Overview

> Read this first. It is the map. Every other architecture doc drills into one box on this map.

---

## 1. What Khatir is (one paragraph)

Khatir is a landlord-first compliance SaaS for Dhaka. The core product lets a landlord digitize the legally-mandated DMP tenant registration form via NID photo OCR, collect rent without forcing tenants to install anything (WhatsApp web-link flow), track per-flat expenses, and view a portfolio dashboard. It is **never** a public listings or public review platform — that is illegal under the Cyber Security Ordinance 2025.

---

## 2. The three client surfaces + one backend

```
┌─────────────────────────────────────────────────────────────────┐
│                          CLIENTS                                  │
│                                                                   │
│   ┌──────────────────┐   ┌──────────────────┐                    │
│   │  Flutter App      │   │  Next.js Admin    │                    │
│   │  (one app)        │   │  Portal           │                    │
│   │                   │   │                   │                    │
│   │  • Landlord shell │   │  ops.khatir...    │                    │
│   │  • Manager shell  │   │  Internal staff   │                    │
│   │  • Tenant shell   │   │  MFA required     │                    │
│   │  Android + iOS    │   │  Desktop web      │                    │
│   └────────┬─────────┘   └────────┬─────────┘                     │
│            │                       │                               │
│            │   Tenant web-link     │                               │
│            │   (no install — served by API as SSR/static)          │
└────────────┼───────────────────────┼──────────────────────────────┘
             │                       │
             │   HTTPS / JSON REST   │
             ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (apps/api)                             │
│                    Django 5 + DRF (monolith)                      │
│                                                                   │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│   │  accounts│ │properties│ │ tenants │ │  rent   │ │ expenses│    │
│   ├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤    │
│   │  leases │ │ dmpforms│ │ pricing │ │  admin  │ │  audit  │    │
│   ├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤    │
│   │notify   │ │feature  │ │ aiproxy │ │warnings │ │ reviews │    │
│   │  flags  │ │  flags  │ │ (client)│ │  (P1)   │ │  (P1)   │    │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│                                                                   │
│   Auth: phone+OTP → JWT  ·  Multi-tenant row-level isolation     │
└──────┬───────────────────┬───────────────────┬───────────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌────────────┐    ┌────────────┐    ┌──────────────────────────────┐
│ PostgreSQL │    │   Redis    │    │  Celery + Celery Beat         │
│    16      │    │  (cache +  │    │  • rent reminders             │
│            │    │  OTP store │    │  • WhatsApp/SMS send queue    │
│            │    │  + broker) │    │  • OCR jobs                   │
└────────────┘    └────────────┘    │  • AI provider calls          │
                                     │  • nightly cleanup            │
                                     └──────────────────────────────┘
       │                                          │
       ▼                                          ▼
┌────────────┐                       ┌──────────────────────────────┐
│ Object     │                       │  services/ai-gateway          │
│ storage    │                       │  (FastAPI — added EPIC-14)    │
│ (S3-compat,│                       │  Provider abstraction:        │
│ encrypted) │                       │  LLM · OCR · ASR · lease-gen  │
│ NID images │                       │  Primary + fallback + usage   │
│ receipts   │                       └──────────────────────────────┘
└────────────┘
```

---

## 3. Components at a glance

| Component | Path | Tech | Who uses it |
|-----------|------|------|-------------|
| Backend API | `apps/api/` | Django 5 + DRF | All clients |
| Mobile app | `apps/mobile/` | Flutter 3.27+ | Landlords, Managers, Tenants |
| Admin portal | `apps/admin/` | Next.js 15 | Internal Khatir staff |
| Tenant web-link | served by `apps/api/` | Django templates / minimal | Tenants without app |
| AI gateway | `services/ai-gateway/` | FastAPI (EPIC-14) | Backend (internal HTTP) |
| Infra | `infra/` | Docker, Compose, GH Actions | DevOps |

---

## 4. Request lifecycle examples

### 4.1 Landlord adds a tenant via NID OCR
1. Flutter app captures NID photo → `POST /api/v1/tenants/ocr` (multipart).
2. Django stores encrypted image to object storage, enqueues Celery OCR job.
3. Celery job calls AI gateway → OCR provider → returns structured fields.
4. Django returns extracted fields to app.
5. Landlord edits/confirms → `POST /api/v1/tenants` persists Tenant + DMPFormRecord.
6. `POST /api/v1/dmpforms/{id}/pdf` generates the print-ready PDF, returns signed URL.

### 4.2 Rent collection (no tenant app)
1. Landlord taps "ask rent" → `POST /api/v1/rent-requests` (recipients).
2. Django creates RentRequest rows, enqueues WhatsApp send jobs.
3. Celery sends WhatsApp template message with unique web-link per tenant.
4. Tenant opens link → minimal web page (served by API) → uploads bKash proof.
5. `POST /api/v1/rent-requests/{token}/proof` stores PaymentProof.
6. Landlord notified → verifies → `POST /api/v1/rent-requests/{id}/verify` → receipt PDF generated + sent back.

### 4.3 Admin changes a pricing tier
1. Staff logs into Next.js admin (MFA) → edits Free tier 2→3.
2. `PATCH /api/v1/admin/pricing-tiers/{id}` with reason.
3. Django writes AdminAuditEntry (before/after diff), updates PricingTier.
4. Change effective within 60s (clients re-fetch config on next load).

---

## 5. Non-negotiable system rules

These are enforced architecturally, not just by convention:

1. **No public surface.** No endpoint returns lists of identifiable people's reputation/reviews publicly. All reputation data is behind auth + consent + row-level ownership checks.
2. **Row-level multi-tenancy.** Every domain query is scoped to the requesting user's ownership. A landlord physically cannot fetch another landlord's data — enforced in base querysets, not just permissions.
3. **Audit everything that writes personal data.** Every create/update/delete on tenant, lease, verification, warning, review, visitor writes an AuditEntry.
4. **NID data is special.** Encrypted at rest, BD-hosted, store result not raw payload, masked in all list views.
5. **Config over code.** Pricing, feature flags, AI providers, reminder cadences live in DB and are admin-configurable. No hardcoded business values.
6. **Kill-switches.** Any reputation/warning/free-text feature can be disabled instantly from the admin portal.

---

## 6. Phasing (which epics build which layer)

- **MVP (EPIC 00–16):** Foundation, auth, properties, tenants+OCR, DMP form, leases, rent collection, expenses, dashboard, pricing, full admin portal.
- **P1 (EPIC 17–23):** NID verification, AI lease, tenant app features, warnings, reviews, B2B manager tier, chatbot.
- **P2 (EPIC 24–25):** History flags, gatekeeper.
- **P3 (EPIC 26):** Government export.

See `docs/epics/_master_plan.md` for the full epic list and dependencies.

---

## 7. Where to look next

- Exact versions & coding standards → `01_stack_and_standards.md`
- Folder layout → `02_project_structure.md`
- Env vars & config layers → `03_env_and_config.md`
- Naming, errors, API envelope → `04_coding_conventions.md`
- Flutter + Next.js + API routing → `05_navigation_routing.md`
- Full database schema → `06_database_schema.md`
- The work itself → `docs/epics/_master_plan.md`
