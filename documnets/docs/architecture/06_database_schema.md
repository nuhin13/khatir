# 06 · Database Schema

> The data model, written to be understood by a human reviewer first and an engineer second. Every table group opens with a plain-language explanation of **what it is, why it exists, and how it's used**, followed by a visual diagram, then the column detail. The SRS §5 is the source of truth for *what data exists*; this document is the engineering detail of *how it's stored and connected*.

---

## How to read this document

Each domain (group of related tables) is presented in four parts:

1. **📖 In plain words** — what this part of the system stores and why, no jargon.
2. **🔄 Data flow** — a diagram showing how data moves in and out, and how tables relate.
3. **🗂️ Tables** — the column-level detail for engineers.
4. **🔑 Key relationships & rules** — the important constraints to keep in mind.

---

## Global conventions (apply to every table)

- Every table automatically gets `created_at` and `updated_at` timestamps (UTC, timezone-aware) from a shared `TimeStampedModel` base. They are not repeated in each table below.
- User-facing records (tenant, lease, building) also get `is_deleted` + `deleted_at` (soft delete) so nothing is ever truly lost.
- IDs are auto-incrementing `bigint` unless a public-facing token is needed.
- Money is always `Decimal(12,2)` in Bangladeshi Taka. Never a floating-point number.
- Status-type fields use fixed enums (see `enums.md`), stored as lowercase text like `"active"`.
- "FK" = Foreign Key = a pointer to a row in another table.

---

# Domain 1 · Accounts & Identity

### 📖 In plain words

This is **who can log in and who they are**. A landlord, a manager, or a tenant all share one `User` table — what differs is their `role`. There are no passwords; people log in with their phone number and a one-time code (OTP) sent over WhatsApp/SMS. The OTP itself isn't kept in the main database — it lives briefly in fast temporary storage (Redis) and disappears after a few minutes.

Two extra tables exist for the business side: `ManagerOwnerLink` (which property-owners a manager is allowed to manage) and `TeamMember` (staff working under a manager). These are wired in early but only fully used when the B2B Manager feature ships.

### 🔄 Data flow

```
   Phone number
       │
       ▼
 ┌──────────────┐   sends 6-digit code    ┌─────────────────────┐
 │  Login screen │ ───────────────────────▶│  Redis (temporary)   │
 └──────────────┘                          │  otp:{phone}         │
       │                                    │  expires in 5 min    │
       │  user enters code                  └─────────────────────┘
       ▼
 ┌──────────────┐   code matches?           ┌─────────────────────┐
 │  Verify OTP   │ ─────────yes────────────▶│   User (Postgres)    │
 └──────────────┘                          │   phone, role, name  │
                                            └─────────┬───────────┘
                                                      │
                        ┌─────────────────────────────┼─────────────────────────────┐
                        ▼                             ▼                             ▼
                 role = landlord              role = manager                role = tenant
                 (owns buildings)        (manages other owners via      (linked to a lease)
                                          ManagerOwnerLink + has
                                          staff via TeamMember)
```

### 🗂️ Tables

**User** — the one account table for all human users.
*Extends Django's auth user; the phone number is the login identity (no username, no password).*

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | Internal unique ID |
| phone | varchar(20), unique | Login identity, E.164 format (`+8801…`) |
| role | enum Role | `landlord` / `manager` / `tenant` / `caretaker` / `admin` — decides which app experience they get |
| name | varchar(120) | Display name |
| language | enum Language | `bn` (default) or `en` — drives all UI text for this user |
| is_active | bool | Disabled accounts can't log in |
| last_login_at | datetime | For support/security visibility |

**OtpCode** — *not a database table.* Lives in Redis as key `otp:{phone}` holding the hashed code, attempt count, and expiry. Auto-deleted after `OTP_TTL_SECONDS` (default 5 min). Documented here so reviewers know where OTP lives.

**ManagerOwnerLink** — connects a manager to the landlords whose properties they manage. *(Wired now, used in EPIC-22.)*

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| manager_id | FK → User | The managing person (role = manager) |
| owner_id | FK → User | The property owner they manage (role = landlord) |
| permissions | jsonb | List of what this manager may do for this owner |

**TeamMember** — staff working under a manager (e.g. an accountant). *(EPIC-22.)*

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| manager_id | FK → User | The manager who employs them |
| member_id | FK → User | The staff member's own account |
| role | varchar | `accountant` / `assistant` / `viewer` |
| scope_owner_ids | jsonb | Which owners' data this staffer may see |

### 🔑 Key relationships & rules

- One `User` row per real person. Role decides everything downstream.
- A manager can link to **many** owners (one-to-many via `ManagerOwnerLink`).
- The OTP is never stored permanently and never logged.

---

# Domain 2 · Properties & Units

### 📖 In plain words

This is **the landlord's real estate**. A `Building` is a physical property (with a name, an area of Dhaka, a full address, and an optional map pin). Each building contains one or more `Unit`s — the individual flats/rooms that get rented out. A unit knows its rent, its type, and whether it's currently occupied, vacant, or under maintenance.

### 🔄 Data flow

```
 ┌─────────┐   owns (1-to-many)   ┌──────────┐   contains (1-to-many)   ┌────────┐
 │  User    │ ────────────────────▶│ Building  │ ────────────────────────▶│  Unit   │
 │ landlord │                      │ name      │                          │ label   │
 └─────────┘                      │ area      │                          │ rent    │
                                   │ address   │                          │ status  │
                                   │ lat/lng?  │ (optional map pin)       └────┬───┘
                                   └──────────┘                                │
                                                                               │ a unit is later
                                                                               │ rented via a Lease
                                                                               ▼
                                                                          (see Domain 4)
```

### 🗂️ Tables

**Building** — a physical property.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| owner_id | FK → User (protect) | The landlord who owns it. "Protect" = can't delete the owner while buildings exist |
| name | varchar(120) | e.g. "Karim Manzil" — required |
| area | enum Area | Dhaka zone (Uttara, Mirpur, …) — required |
| address | text | Full address — required, printed on the DMP form |
| lat | decimal(9,6), nullable | Optional map-pin latitude |
| lng | decimal(9,6), nullable | Optional map-pin longitude |

**Unit** — one rentable flat/room inside a building.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| building_id | FK → Building (cascade) | Its parent building. "Cascade" = deleting a building removes its units |
| label | varchar(40) | e.g. "4B" |
| type | enum UnitType | apartment / room / commercial / garage / other |
| rent | Decimal(12,2) | Monthly rent in Taka |
| amenities | jsonb | List of amenities |
| status | enum UnitStatus | occupied / vacant / maintenance |
| available_from | date, nullable | When it becomes available |

### 🔑 Key relationships & rules

- A landlord can only ever see their own buildings (enforced by the `for_user` rule — see conventions doc).
- Map pin is optional; address is mandatory because the DMP form needs it.

---

# Domain 3 · Tenants & NID

### 📖 In plain words

This is **the people renting the flats and their identity documents**. The `Tenant` record holds the person's name and their National ID details. Because NID data is highly sensitive (and legally protected), the full NID number is **encrypted** in the database, and a **masked** version (`****7788`) is what shows up in any list or search. Family members living with the tenant are stored separately so they can be listed on the police (DMP) form.

A tenant may or may not install the app. If they do, their `Tenant` record links to a `User` account.

### 🔄 Data flow

```
 NID photo
    │
    ▼
 ┌──────────┐   OCR extracts fields   ┌────────────────────────────┐
 │ Camera    │ ───────────────────────▶│  Tenant                     │
 │ capture   │                         │  name                       │
 └──────────┘                         │  nid_number_enc  (encrypted)│
                                       │  nid_number_masked ****7788 │
                                       │  photo_ref → encrypted file │
                                       │  verification_status        │
                                       └──────┬─────────────┬────────┘
                                              │             │
                              has family?     │             │ installs app?
                                              ▼             ▼
                                  ┌────────────────────┐  links to → User
                                  │ TenantFamilyMember  │
                                  │ name, relation      │
                                  └────────────────────┘
```

### 🗂️ Tables

**Tenant** — a renter's identity record.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| name | varchar(120) | Full name |
| nid_number_enc | bytea (encrypted) | The real NID number, encrypted at rest |
| nid_number_masked | varchar(20) | `****7788` — safe to show/search |
| dob | date, nullable | Date of birth |
| address | text | Permanent address (from NID) |
| photo_ref | varchar | Pointer to the encrypted NID image in object storage |
| verification_status | enum VerificationStatus | unverified / matched / not_matched / error (verification is P1) |
| verified_at | datetime, nullable | When EC verification happened |
| is_app_user | bool | Has this tenant installed the app? |
| linked_user_id | FK → User, nullable | Their app account, if any |

**TenantFamilyMember** — household members listed on the DMP form.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| tenant_id | FK → Tenant (cascade) | The head tenant |
| name | varchar(120) | Family member name |
| relation | varchar(40) | Relationship to tenant |

### 🔑 Key relationships & rules

- **NID data is special:** full number encrypted, masked for display, image encrypted. Never logged in plaintext.
- A tenant exists independent of any lease (you can register someone before finalizing the lease).

---

# Domain 4 · Leases & Rent Schedule

### 📖 In plain words

This is **the rental agreement and the monthly rent calendar**. A `Lease` ties together three things: a unit, a tenant, and the landlord — plus the rent amount, advance, and start/end dates. Once a lease is active, the system automatically creates a `RentSchedule` — a row for each month saying "rent of ৳X is due on day Y." That schedule is what later triggers rent requests.

### 🔄 Data flow

```
  Unit + Tenant + Landlord
        │
        ▼
   ┌─────────┐   when active, auto-generates monthly   ┌──────────────┐
   │  Lease   │ ───────────────────────────────────────▶│ RentSchedule  │
   │ rent     │                                         │ period 2026-05│
   │ advance  │                                         │ due_day 5     │
   │ start    │                                         │ amount        │
   │ end      │                                         │ status        │
   │ status   │                                         └──────┬───────┘
   └─────────┘                                                 │
                                                               │ each month's schedule
                                                               │ triggers a rent request
                                                               ▼
                                                          (see Domain 5)
```

### 🗂️ Tables

**Lease** — the rental contract.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| unit_id | FK → Unit (protect) | Which flat |
| tenant_id | FK → Tenant (protect) | Who's renting |
| landlord_id | FK → User | The owner |
| start_date / end_date | date | Lease term |
| rent | Decimal(12,2) | Monthly rent |
| advance | Decimal(12,2) | Advance/deposit held |
| status | enum LeaseStatus | draft / active / ended / terminated |
| signed_pdf_ref | varchar, nullable | Signed agreement PDF (P1 e-sign) |

**RentSchedule** — one row per rent period (month).

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| lease_id | FK → Lease (cascade) | Parent lease |
| period | varchar(7) | The month, e.g. `2026-05` |
| due_day | int | Day of month rent is due (e.g. 5) |
| due_date | date | The concrete due date for this period |
| amount | Decimal(12,2) | How much is due |
| status | enum RentScheduleStatus | pending / requested / paid / overdue |
| sent_at | datetime, nullable | When the request went out |

### 🔑 Key relationships & rules

- A lease has many monthly schedule rows.
- The scheduler (a background job) walks active leases and creates/updates schedule rows.

---

# Domain 5 · Rent Collection

### 📖 In plain words

This is **the signature feature: collecting rent without forcing the tenant to install anything**. When rent is due, the landlord sends a `RentRequest`. The tenant gets a WhatsApp message with a unique link to a simple web page (no app needed). On that page they submit a `PaymentProof` — a bKash transaction ID, a screenshot, or a note. The landlord reviews it and confirms; that confirmation creates a `Payment` record and generates a receipt.

### 🔄 Data flow

```
 ┌──────────┐  "ask for rent"   ┌──────────────┐   WhatsApp link    ┌──────────────────┐
 │ Landlord  │ ─────────────────▶│  RentRequest  │ ──────────────────▶│ Tenant web page   │
 └──────────┘                   │  link_token   │  (no app needed)   │  /r/{token}       │
                                │  amount       │                    └────────┬─────────┘
                                │  status: sent │                             │ uploads proof
                                └──────┬───────┘                             ▼
                                       │                          ┌────────────────────┐
                                       │  status:                 │  PaymentProof        │
                                       │  proof_submitted ◀────────│  bkash txn / photo   │
                                       ▼                          └────────────────────┘
                                ┌──────────────┐  landlord taps "received"   ┌──────────┐
                                │ Landlord      │ ───────────────────────────▶│ Payment   │
                                │ verifies      │                            │ receipt   │
                                └──────────────┘                            │ generated │
                                                                            └──────────┘
```

### 🗂️ Tables

**RentRequest** — a single ask-for-rent event.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| rent_schedule_id | FK → RentSchedule, nullable | The scheduled month (null if a one-off manual request) |
| lease_id | FK → Lease | The lease this belongs to |
| amount | Decimal(12,2) | Amount requested |
| period | varchar(7) | Which month |
| link_token | varchar, unique | Secret token in the tenant's web-link URL |
| sent_via | enum Channel | whatsapp / sms / inapp |
| sent_at | datetime | When sent |
| status | enum RentRequestStatus | sent / proof_submitted / verified / rejected |

**PaymentProof** — what the tenant submits as evidence.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| rent_request_id | FK → RentRequest | The request being answered |
| type | enum PaymentProofType | bkash_txn / nagad_txn / screenshot / photo / note |
| value | varchar | Transaction ID or note text |
| photo_ref | varchar, nullable | Screenshot/photo in storage |
| submitted_at | datetime | When submitted |

**Payment** — the confirmed, verified payment.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| rent_request_id | FK → RentRequest | The settled request |
| verified_at | datetime | When the landlord confirmed |
| verified_by_id | FK → User | Who confirmed |
| receipt_ref | varchar | Generated receipt PDF in storage |

### 🔑 Key relationships & rules

- The `link_token` is a signed, single-purpose, expiring token — it grants access to **one** rent request's page only, with no login.
- A landlord can also mark "received" directly (cash in person) without any tenant action.

---

# Domain 6 · Maintenance & Expenses

### 📖 In plain words

This is **repairs and money spent on units**. A tenant reports a problem (a `MaintenanceRequest` — "the tap is leaking"). The landlord fixes it and records the cost, which automatically becomes an `Expense`. Landlords can also log expenses directly without a request (e.g. annual painting). All expenses roll up into the dashboard and tax reports.

### 🔄 Data flow

```
 ┌────────┐  reports problem   ┌────────────────────┐  landlord resolves   ┌──────────┐
 │ Tenant  │ ──────────────────▶│ MaintenanceRequest  │ ────with cost───────▶│ Expense   │
 └────────┘                    │ category, photo     │                     │ amount    │
                               │ status: open        │                     │ category  │
                               └────────────────────┘                     │ source:   │
                                                                           │ request   │
 ┌──────────┐  logs directly                                               └────┬─────┘
 │ Landlord  │ ───────────────────────────────────────────────────────────────▶│
 └──────────┘   (Expense with source = manual)                                  ▼
                                                                       rolls into Dashboard
                                                                       (Domain 7)
```

### 🗂️ Tables

**MaintenanceRequest** — a reported repair need.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| unit_id | FK → Unit | Which flat |
| lease_id | FK → Lease, nullable | The active lease, if any |
| category | enum MaintenanceCategory | plumbing / electrical / paint / … |
| description | text | What's wrong |
| photo_ref | varchar, nullable | Photo of the problem |
| status | enum MaintenanceStatus | open / resolved |
| resolved_at | datetime, nullable | When fixed |
| resolution_cost | Decimal(12,2), nullable | What it cost |
| resolution_note | text, nullable | Notes on the fix |

**Expense** — money spent on a unit.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| unit_id | FK → Unit | Which flat |
| category | enum ExpenseCategory | plumbing / paint / electrical / … |
| amount | Decimal(12,2) | Cost |
| date | date | When incurred |
| source | enum ExpenseSource | request (came from a maintenance request) / manual |
| note | text | Description |
| receipt_ref | varchar, nullable | Receipt image |

### 🔑 Key relationships & rules

- Resolving a maintenance request **automatically** creates an Expense with `source = request`.
- Manual expenses have `source = manual` and no parent request.

---

# Domain 7 · Pricing & Subscriptions

### 📖 In plain words

This is **how money is charged and what plan each landlord is on**. The available plans live in `PricingTier` (Free, Per-tenant, Bundles, Unlimited) — and crucially, **these are editable from the admin portal, not hardcoded**. Each landlord has a `Subscription` saying which tier they're on and when they're billed next.

### 🔄 Data flow

```
 ┌────────────────┐   admin edits tiers live    ┌──────────────────┐
 │  Admin portal   │ ───────────────────────────▶│  PricingTier      │
 └────────────────┘                             │  free / bundles…  │
                                                 │  prices, limits   │
                                                 └────────┬─────────┘
                                                          │ a landlord subscribes to one tier
                                                          ▼
                                  ┌────────┐         ┌──────────────┐
                                  │  User   │ ───────▶│ Subscription  │
                                  │ landlord│         │ tier, status  │
                                  └────────┘         │ next_billing  │
                                                     └──────────────┘
```

### 🗂️ Tables

**PricingTier** — an available plan (admin-editable).

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| key | varchar, unique | Stable code: free / per_tenant / bundle_20 / … |
| label / label_bn | varchar | Display names (English / Bangla) |
| tenant_min / tenant_max | int (max null = unlimited) | Tenant count range this tier covers |
| monthly_price / annual_price | Decimal, nullable | Prices |
| includes_verification | bool | Does this tier allow NID verification? |
| included_credits | int | Bundled verification credits |
| active | bool | Is this tier offered right now? |
| sort_order | int | Display order |

**Subscription** — a landlord's current plan.

| Column | Type | What it's for |
|--------|------|---------------|
| id | bigint PK | |
| user_id | FK → User | The subscriber |
| tier_id | FK → PricingTier | Their plan |
| billing_cycle | enum BillingCycle | monthly / annual |
| status | enum SubscriptionStatus | active / past_due / cancelled |
| start_at / next_billing_at | datetime | Billing dates |

### 🔑 Key relationships & rules

- Free tier = first 2 tenants, no NID verification, ৳0. The "2" lives in `SystemConfig`, not in code.
- Changing a tier in the admin portal affects clients within ~60 seconds.

---

# Domain 8 · Platform & Admin

### 📖 In plain words

This is **the machinery that runs the business behind the scenes** — internal staff accounts, the on/off switches for features, the emergency kill-switches, the configurable AI providers, the notification system, and the audit logs that record everything. Almost none of this is visible to landlords; it's the control room.

### 🔄 Data flow

```
 ┌────────────────┐
 │  Admin portal   │  (internal staff, MFA required)
 └───────┬────────┘
         │ every action is recorded
         ├──────────────▶ AdminAuditEntry  (who changed what, before/after)
         │
         ├── manage ────▶ AdminUser        (staff accounts + roles)
         ├── toggle ────▶ FeatureFlag       (turn features on/off)
         ├── emergency ─▶ KillSwitchEvent   (disable risky features instantly)
         ├── tune ──────▶ SystemConfig      (limits, fees, cadences)
         ├── configure ─▶ AIProvider        (swap LLM/OCR/voice/lease vendors)
         │                     │
         │                     └─ usage tracked in ─▶ AIUsageLog
         └── broadcast ─▶ Notification ──────▶ NotificationDelivery (per recipient)
                              ▲
                              └── reusable ─── NotificationTemplate (auto-triggered)

 Meanwhile, end-user actions (create tenant, verify rent, etc.)
 are recorded in ─────▶ AuditEntry
```

### 🗂️ Tables (summary — full detail in admin spec)

**AdminUser** — internal staff account (separate from `User`). email, name, password_hash, mfa_secret, role (super/ops/finance/compliance/support), scope, disabled, last_login_at.

**AdminAuditEntry** — every admin action, with before/after JSON diff, IP, reason.

**AuditEntry** — every consequential end-user action on personal data.

**FeatureFlag** — key, description, scope (global/role/user), enabled, value_json.

**KillSwitchEvent** — a record each time a kill-switch is flipped: switch_key, action, reason, lawyer_reference.

**SystemConfig** — admin-tunable business values: key, value, type (int/money/text/bool), description, effective_from.

**AIProvider** — a configurable AI vendor per category: category (chat/voice/ocr/lease), provider_key, is_primary/is_fallback, model_name, api_key_enc (encrypted), endpoint_url, params_json, dpa_reference, active.

**AIUsageLog** — per-call usage: provider, category, request_count, tokens_used, cost_usd, success, latency_ms, failover_from.

**Notification** — a broadcast: who sent it, audience type + filter, channels, bilingual title/body, schedule, status, sent/delivered/opened counts, cost.

**NotificationDelivery** — one row per recipient per channel: status, delivered_at, opened_at, error.

**NotificationTemplate** — reusable auto-triggered messages (rent reminder, welcome, etc.): bilingual title/body, trigger_event, channels, variables.

### 🔑 Key relationships & rules

- `AdminUser` is a **separate table** from `User` — staff never share auth with customers.
- Every admin write produces an `AdminAuditEntry`; every personal-data write produces an `AuditEntry`. Non-negotiable.
- AI provider API keys are encrypted; for NID OCR a non-BD provider requires a `dpa_reference` before it can be saved.

---

# Domain 9 · Reputation, Verification & Gatekeeper (later phases)

### 📖 In plain words

These tables support features that ship **after the MVP** and are legally sensitive, so they're built with extra care: private warnings between a landlord and tenant, mutual reviews, factual history flags, EC identity verification, visitor logs for building gatekeepers, and the consent/right-of-reply records that keep all of it lawful. None of this is ever public.

### 🗂️ Tables (schema-ready, built in their phase)

| Table | Phase | What it stores |
|-------|-------|----------------|
| VerificationLog | P1 (EPIC-17) | Each EC NID check: result, who asked, consent ref. **Never the raw EC payload.** |
| Warning | P1 (EPIC-20) | A private landlord→tenant factual notice tied to a lease |
| Review | P1 (EPIC-21) | Mutual review between consenting app users, visible only to that pair |
| HistoryFlag | P2 (EPIC-24) | Structured factual lease outcome (rent on time, lease completed, etc.) |
| RightOfReply | P1/P2 | A subject's response attached to any warning/review/flag |
| ConsentRecord | cross | A logged consent (who consented, to what, when it expires) |
| VisitorLog | P2 (EPIC-25) | A gate visitor entry: name, phone, destination flat, photo, admitted-by. 90-day retention. |

### 🔑 Key relationships & rules

- Everything here is private + consent-gated + right-of-reply enabled + kill-switchable. This is a hard legal requirement, not a preference.
- Raw NID verification payloads are never stored — only the matched/not-matched result.

---

## Indexes (engineering minimum)

Add a database index for: every foreign key, every status field used in filters, and every column used in a `for_user` scope. Concretely at minimum:

`Building(owner_id)` · `Unit(building_id, status)` · `Tenant(nid_number_masked)` · `Lease(landlord_id, status)` · `Lease(unit_id)` · `RentSchedule(lease_id, status)` · `RentRequest(link_token)` · `RentRequest(lease_id, status)` · `Expense(unit_id, date)` · `Subscription(user_id, status)` · `AuditEntry(actor_user_id, created_at)` · `AdminAuditEntry(admin_user_id, created_at)` · `NotificationDelivery(notification_id, status)`

---

## Migration discipline

- One logical change per migration; reversible unless impossible (note why in the task).
- Data migrations separate from schema migrations.
- Never edit a merged migration — add a new one.
- CI runs `makemigrations --check` so no model change ships without its migration.
- Changing the encryption key requires a dedicated re-encryption data migration.

---

## Rules for agents touching the schema

1. New model → correct Django app per `02_project_structure.md`; inherits `TimeStampedModel`; status fields are enums; add a `for_user` manager if user-owned; audit on writes.
2. Money is `Decimal(12,2)`; datetimes are tz-aware UTC.
3. Sensitive personal fields (NID, etc.) get an encrypted column **and** a masked column. Never plaintext, never logged.
4. Add indexes for every new FK and filtered status field.
5. When you add or change a table, **update both this document's relevant domain section (plain words + diagram + table) and `enums.md`** if a new enum is involved. The human-readable explanation is part of "done," not optional.
