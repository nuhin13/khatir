# Admin Portal Specification — Khatir (খাতির)
**Version:** 1.0
**Companion docs:** `01_BRD_Khatir.md`, `02_SRS_Khatir.md`, `03_Backlog_and_Flows_Khatir.md`

---

## 1. Purpose

The Admin Portal is the **operational control center** for Khatir. It is a separate web application (not a mode within the mobile app) used exclusively by Khatir staff to:

1. Configure pricing, tiers, and system behavior without code changes.
2. Manage users, accounts, and subscriptions.
3. Monitor platform health and respond to compliance/legal events.
4. Toggle features and kill-switches in response to legal or operational needs.
5. Investigate issues and provide customer support.

The portal is **desktop-first** (admins work from laptops/PCs) and **English-first** (internal operations language), with full audit trails on every action.

---

## 2. Access Model

### 2.1 Admin roles

| Role | Permissions | Typical user |
|------|-------------|--------------|
| **Super Admin** | All. Can create/disable other admins. | Founder, CTO |
| **Ops Admin** | User/account management, subscriptions, refunds. Cannot edit pricing or kill-switches. | Support lead |
| **Finance Admin** | Subscription/billing/invoice management. Pricing read-only. Cannot touch user data beyond billing. | Finance Ops |
| **Compliance Admin** | Audit logs, kill-switches, verification logs, consent records. Cannot manage users or pricing. | DPO / Legal liaison |
| **Support Agent** | Read-only user records, can suspend/refund individual subscriptions. Cannot delete data or change global settings. | Support reps |

### 2.2 Authentication

- **Phone+OTP not allowed for admins.** Email + password + **MFA (TOTP via Authenticator app)** mandatory.
- Failed login lockout after 5 attempts in 10 min.
- IP allowlist option (configurable by Super Admin).
- Session timeout: 30 min idle, 8 hr max.
- All admin actions audit-logged with IP, user-agent, timestamp, before/after values.

### 2.3 Separation from end-user system

- Admin accounts live in a separate `AdminUser` table — never share auth with end-users.
- Admin portal hosted on a separate subdomain (e.g., `ops.khatir.com.bd`).
- Admin portal can be IP-restricted at the network edge as additional defense.

---

## 3. Information Architecture

### 3.1 Navigation (sidebar)

```
🏠  Dashboard                    (overview, KPIs)
👥  Users & Accounts             (search, view, suspend)
    ├── Landlords
    ├── Tenants
    ├── Managers (B2B)
    └── Caretakers (P2)
💰  Pricing & Subscriptions      (tiers, billing)
    ├── Tier configuration
    ├── Active subscriptions
    ├── Invoices
    └── Refund queue
🚀  Feature Management           (flags, kill-switches)
    ├── Feature flags
    ├── Kill-switches
    └── A/B experiments
📤  Notifications                (compose, send, track)
    ├── Compose
    ├── History
    └── Templates
🤖  AI Providers                 (LLM, voice, OCR, lease-gen)
    ├── Chat / LLM
    ├── Voice / ASR
    ├── OCR / Vision
    └── Lease generation
📋  Compliance                   (audit, consent, verification)
    ├── Audit log
    ├── Consent records
    ├── Verification logs
    └── Data export/delete requests
🛠️  System Config                (reminder cadence, retention, etc.)
🆘  Support                      (open tickets, escalations)
👤  Admin Users                  (Super Admin only)
📊  Analytics                    (platform-wide metrics)
🔒  Security                     (IP allowlist, audit alerts)
```

---

## 4. Module Specifications

### 4.1 Dashboard (P0)

**Purpose:** at-a-glance health of the platform.

**Components:**
- **KPI tiles:** Total accounts, paying subscribers, MRR, churn rate (30d), new signups today.
- **Activity feed:** last 20 platform events (signups, subscriptions, kill-switch toggles, large refunds).
- **Health chart:** API uptime, OCR success rate, WhatsApp delivery rate (last 7 days).
- **Alerts panel:** anything requiring admin attention (failed payments, abuse reports, system errors).

**Acceptance:** dashboard loads in <1.5s on broadband; KPI tiles refresh every 60s.

---

### 4.2 Users & Accounts (P0)

**Purpose:** find, inspect, and manage any user account.

**Features:**
- **Search** by phone number, name, NID number (masked search — never shows full NID in list), email, account ID.
- **Filter** by role, status, tier, signup date, location.
- **User detail page** showing:
    - Profile (name, phone, role, language, account age)
    - Subscription status and history
    - Buildings/units/tenants owned (for landlords) or leased (for tenants)
    - Recent activity (last 50 actions)
    - Audit log entries involving this user
    - Notes (admin-only, free-text — for support context)
- **Actions** (role-gated):
    - Suspend account (with reason)
    - Reactivate
    - Force-logout from all devices
    - Reset MFA / OTP
    - Issue refund
    - Add admin note
    - **Soft-delete account** (Compliance Admin only, full audit + tenant notification)

**Acceptance:** support agent can find a user by phone in <5s; user actions logged with reason; soft-delete cascades correctly and is reversible within 30 days.

---

### 4.3 Pricing & Subscriptions (P0)

**The most critical config module.** Everything is admin-configurable per the BRD/SRS requirement.

#### 4.3.1 Tier Configuration

| Field | Type | Notes |
|-------|------|-------|
| Tier key | text (immutable once created) | `free`, `per_tenant`, `bundle_20`, `bundle_40`, `unlimited_monthly`, `unlimited_annual` |
| Display label (English) | text | "Unlimited Monthly" |
| Display label (Bangla) | text | "অনিয়মিত মাসিক" |
| Tenant min | int | 1 |
| Tenant max | int or "unlimited" | 2 |
| Monthly price (BDT) | decimal | 0 |
| Annual price (BDT) | decimal or null | null if not annual |
| Includes NID verification | toggle | false for free |
| Included verification credits | int | 0 |
| Active | toggle | true |
| Sort order | int | 1 |

**Editing UI:**
- Visual editor (no JSON editing) — each tier as a card with inline-edit fields.
- **Live impact preview** before save: "Changing free tier from 2 → 3 tenants will move 1,247 paying landlords back to free. Estimated MRR impact: −Tk 87,290/mo."
- **Confirmation modal** with reason field (required).
- **Audit log entry** generated on save with before/after diff.
- **Scheduled rollout option**: take effect immediately, at midnight, at start of next billing cycle.

#### 4.3.2 Active Subscriptions

- Table of all paying subscriptions.
- Columns: landlord name, tier, started_at, next_billing_at, MFS account, status (active/past_due/cancelled).
- Filter by tier, status, billing date.
- Action: cancel, refund, change tier, extend trial.

#### 4.3.3 Invoices & Refund Queue

- All generated invoices searchable.
- Refund queue: refund requests pending review with reason, amount, requester.
- Refund approval workflow (Ops Admin requests → Finance Admin approves >Tk 5,000).

**Acceptance:** Super Admin can change Free tier from 2 → 3 tenants; impact preview shows accurate number of affected landlords; change takes effect within 60s of save with audit trail.

---

### 4.4 Feature Management (P0)

**Purpose:** turn features on/off without redeploying.

#### 4.4.1 Feature flags

Granular flags per feature, optionally scoped:

| Flag | Description | Default | Scope |
|------|-------------|---------|-------|
| `intro_slides_v2` | Show new intro slide variant | off | A/B 50/50 |
| `voice_form_fill` | Enable Bangla voice tenant onboarding | on | global |
| `nid_verification` | EC NID verification | off (until P1) | global |
| `ai_lease_gen` | AI lease generation | off (until P1) | global |
| `warnings_feature` | Private warnings system | off (until legal sign-off) | global |
| `gatekeeper_module` | Caretaker QR visitor logging | off (until P2) | per-building opt-in |
| `tenant_app_signup` | Allow tenants to self-register | on | global |
| `mutual_reviews` | Reviews between app-using parties | off (until P1) | global |
| `history_flags` | Phase 2 reputation graph | off | requires explicit per-account allowlist |

**UI:** simple toggle list with description, scope, last-changed-by, last-changed-at.

#### 4.4.2 Kill-Switches (★ legally critical)

A **separate, prominent panel** specifically for emergency disable. Visually distinct (red header).

Switches:
- **Warnings system** — disables all warning creation + hides existing warning UI on next client refresh.
- **Reviews system** — same for mutual reviews.
- **History flags** — disables Phase 2 reputation viewing entirely.
- **Free-text fields** — disables all free-text in warnings/reviews/flags (forces structured-only).
- **Tenant app reviews** — disables only the tenant-side reviewing.
- **All public-facing features** — emergency master switch.

Each kill-switch action requires:
1. Confirmation modal.
2. Reason text (mandatory, min 20 chars).
3. Lawyer reference (optional but recommended).
4. MFA re-prompt.

Audit entry includes all of the above + which features were affected.

#### 4.4.3 A/B Experiments

Configure experiment buckets (e.g., 50/50 intro slide order) and view conversion metrics per arm.

**Acceptance:** Compliance Admin can toggle warnings off; UI for warnings disappears in all client apps within 60s on next refresh; audit log captures who/why/when.

---

### 4.5 Notifications (P0)

**Purpose:** compose and send notifications from admin to end-user audiences across multiple channels.

#### 4.5.1 Compose tab

Step-by-step composer with live preview:

**Audience targeting:**
| Type | Description |
|------|-------------|
| All users | Entire platform (~4,832 today) |
| By role | Multi-select checkbox: Landlord, Manager, Tenant, Caretaker |
| By segment | Pre-built segments: paying landlords, free-tier with ≥2 tenants (upgrade candidates), inactive 30d+, past-due, by location, by building count |
| Specific users | Search + multi-select individual users |

**Channels** (multi-select):
| Channel | Cost (illustrative) | Notes |
|---------|---------------------|-------|
| In-app | Free | Notification bell + push if PWA supports |
| WhatsApp | ৳0.5/msg | Via Business API templates |
| SMS | ৳0.3/msg | Fallback for non-WhatsApp |
| Email | Free | For users with email on file |

**Composition:**
- Title (English) + Title (Bangla)
- Body (English) + Body (Bangla)
- Template variables: `{name}`, `{unit}`, `{tier}`, `{rent_amount}`, `{building_name}` — auto-substituted per recipient
- User sees the version matching their language preference

**Live preview pane:**
- WhatsApp bubble preview with chat-app styling
- In-app notification preview
- Email preview (subject + body)

**Scheduling:**
| Type | Use case |
|------|----------|
| Immediately | Urgent / time-sensitive |
| Scheduled | Specific datetime |
| Recurring | Daily/weekly/monthly with end condition |

**Send confirmation:**
- Reach summary (recipient count from audience filter)
- Cost estimate (channels × recipients × per-channel cost)
- Delivery time estimate
- Confirm button → MFA re-prompt if cost >Tk 5,000 → audit-logged

#### 4.5.2 History tab

Searchable, filterable, exportable table:
- Sent at, title, audience description, channels used
- Sent count, delivered count, opened count
- Status (delivered / partial / failed)
- Sender admin user
- Click row → full detail with per-recipient delivery status

#### 4.5.3 Templates tab

Auto-triggered notifications (admin-editable templates):

| Template | Trigger | Default channels |
|----------|---------|------------------|
| Rent reminder (1st) | 24h after rent request unverified | WhatsApp |
| Rent reminder (2nd) | 48h after rent request unverified | WhatsApp + SMS |
| Welcome — new landlord | First signup | WhatsApp + in-app |
| Free tier limit reached | Landlord adds 3rd tenant | In-app + WhatsApp |
| Payment received | Landlord verifies rent | WhatsApp + in-app |
| Maintenance resolved | Landlord marks request done | In-app |
| Subscription expiring | 7d before billing date | WhatsApp + email |
| NID verification result | After EC API call | In-app |

Each template editable for: title (EN/BN), body (EN/BN), channels, enabled/disabled.

**Compliance constraints:**
- Tenant opt-out respected for promotional notifications.
- Transactional notifications (rent due, receipt, security) always sent.
- All admin-initiated sends audit-logged with sender, full content, audience criteria.
- No PII in notification logs beyond user IDs.

**Acceptance:** admin can compose a bilingual notification, target "free-tier landlords with ≥2 tenants" (412 users), send via WhatsApp + in-app, see reach/cost preview (~Tk 206), confirm with MFA, and view delivery progress in History within 60 seconds.

---

### 4.6 AI Providers (P0)

**Purpose:** swap AI providers (LLM, voice, OCR, lease-gen) without code changes — critical for cost control, fallback resilience, and provider experimentation.

#### 4.6.1 Tabs

Four tabs, one per AI category:

| Tab | Use cases | Supported providers |
|-----|-----------|---------------------|
| **Chat / LLM** | Support chatbot, AI summaries, lease-gen text | OpenAI · Anthropic Claude · OpenRouter · Google Gemini · Self-hosted (Ollama) |
| **Voice / ASR** | Bangla voice tenant onboarding (FR-3.3), voice chatbot | Verbex · Google Speech-to-Text · OpenAI Whisper · Azure Speech · Self-hosted Whisper |
| **OCR / Vision** | NID extraction (FR-3.2) | Google Cloud Vision · Azure Document Intelligence · AWS Textract · Tesseract (self-hosted) |
| **Lease generation** | DNCC-compliant rental agreements (FR-8.1) | Anthropic Claude · OpenAI · Google Gemini |

#### 4.6.2 Per-category configuration

For each provider available within a category:
- Provider name + supported models dropdown
- Selected/unselected indicator (radio-style)
- Primary / Fallback badge
- Cost per unit (per 1K tokens, per minute, per call)

**Active configuration panel:**
- Primary provider (read-only summary)
- Model selection (dropdown from supported models)
- API key (encrypted at rest, masked in UI, eye-toggle, copy button)
- Endpoint URL (for self-hosted only, OpenAI-compatible format)
- Temperature + max tokens + other model params
- Fallback chain summary
- **Test connection button** — issues a minimal test call and shows pass/fail with latency
- Save button

#### 4.6.3 Usage tracking

Per category, last 30 days:
- Request count
- Tokens used / minutes processed
- Total cost (USD)
- Success rate %
- Average latency
- Failover events log (when primary fell back to secondary)

#### 4.6.4 Runtime failover

When a request to the primary provider fails (timeout >30s, 5xx, rate limit, auth error):
1. System catches the error.
2. Routes the request to the configured fallback provider.
3. Logs the failover event with reason, timestamp, original provider, fallback provider.
4. If fallback also fails → returns user-facing error + alerts admin via dashboard.

#### 4.6.5 NID data residency constraint

OCR provider for NID extraction is **constrained**:
- Provider must be either BD-hosted (self-hosted Tesseract) OR
- Covered by a signed Data Processing Agreement (DPA) on file.

Admin portal **enforces at save-time** with a warning and required DPA reference if selecting a non-BD-hosted OCR provider for NID use. Cannot save without acknowledgment.

#### 4.6.6 Custom endpoint support

For self-hosted or alternative providers:
- Custom endpoint URL field (OpenAI-compatible format)
- Custom model name
- Custom headers (key-value pairs for auth, etc.)

This enables future provider additions without code changes (e.g., Cohere, Mistral, local LLaMA, future providers).

**Acceptance:** admin can swap chatbot LLM from Claude Sonnet to GPT-4o, configure OpenAI as fallback, click test connection (returns OK in <3s), save, and the next chatbot request uses GPT-4o — all within 60 seconds and audit-logged. For OCR, admin attempting to select a non-BD provider sees a DPA warning before save.

---

### 4.7 Compliance (P0)

**Purpose:** legal and regulatory observability.

#### 4.5.1 Audit Log

Searchable, filterable log of every action of consequence:

| Filter | Example |
|--------|---------|
| Actor type | admin, landlord, tenant, system |
| Actor ID | specific user/admin |
| Action | login, suspend_user, change_tier, kill_switch_toggle, nid_verify_request, etc. |
| Target | user ID, lease ID, building ID |
| Date range | last 24h, last 7d, custom |

Each entry shows: timestamp, actor, action, target, IP, user-agent, before/after JSON (for state-changing actions), result (success/failure).

**Export:** CSV download (Compliance Admin only) for legal requests.

#### 4.5.2 Consent Records

All consent captures (tenant consent to NID verification, history flag visibility consent, etc.) — searchable by subject_tenant_id, purpose, date.

#### 4.5.3 Verification Logs

NID verification attempts: timestamp, requestor (landlord), result (matched/not_matched/error), consent reference, raw payload **never stored**.

#### 4.5.4 Data Export / Delete Requests

Queue of GDPR/PDPA-style requests from end users:
- Export my data (returns ZIP of all user-associated data within 30 days).
- Delete my account (initiates soft-delete with 30-day undo window).

Compliance Admin reviews, approves, and tracks SLA compliance.

**Acceptance:** Compliance Admin can pull a complete audit trail for any user in <30s; data export requests fulfilled within 30 days with full audit trail.

---

### 4.8 System Configuration (P0)

**Purpose:** non-pricing system behavior tuning.

Configurable values:

| Key | Default | Description |
|-----|---------|-------------|
| `rent_reminder_1_hours` | 24 | Hours after request before first nudge |
| `rent_reminder_2_hours` | 48 | Hours before second nudge |
| `verification_fee_bdt` | 75 | NID verification fee shown to user |
| `visitor_log_retention_days` | 90 | Auto-purge after this many days |
| `dmp_form_template_version` | v2.1 | Which DMP template to render |
| `lease_template_version` | v1.0 | Which lease template AI uses |
| `referral_reward_months` | 1 | Free months for referring a paying landlord |
| `max_buildings_per_account` | unlimited | Hard limit |
| `support_whatsapp_number` | +880... | Shown in app for support |
| `intro_slide_skip_allowed` | true | Whether users can skip intro |

Each setting:
- Validation (type, range).
- Default value documented.
- Effective-from timestamp on update.
- Audit log.

**Acceptance:** changing `rent_reminder_1_hours` from 24 to 12 takes effect for all newly-created rent requests within 60s.

---

### 4.9 Support (P1)

**Purpose:** ticket management for customer issues.

- Open tickets queue with priority.
- Linked to user account for context.
- WhatsApp message templates for common responses.
- Internal notes.
- Escalation workflow.

(P1 — basic implementation MVP; full helpdesk integration later.)

---

### 4.10 Admin User Management (P0)

**Purpose:** manage who has admin access.

- Create new admin (Super Admin only): email, name, role, scope.
- Force MFA setup on first login.
- Disable admin.
- View admin activity (everything they've done).
- Rotate access tokens.

---

### 4.11 Analytics (P1)

**Purpose:** product and business intelligence.

Pre-built dashboards:
- **Acquisition:** signups by source, by location, by week.
- **Activation:** % of signups who complete first DMP form, who add first tenant, who send first rent request.
- **Revenue:** MRR, ARR, ARPU by tier, conversion from free → paid.
- **Retention:** cohort curves, churn by tier, churn by tenure.
- **Feature usage:** DMP forms generated/week, voice fills vs photo fills, rent requests sent, verification rate.
- **Compliance:** verification consent rates, kill-switch toggles, audit query volume.

Each chart exportable as PNG/CSV.

---

### 4.12 Security (P1)

- IP allowlist management.
- Audit alerts (e.g., "alert me if any admin uses kill-switch").
- Security event log.
- Suspended/failed login attempts.

---

## 5. Data Model Additions

Extends `02_SRS_Khatir.md` §5:

- **AdminUser** (id, email, name, password_hash, mfa_secret, role, scope, disabled, created_at, last_login_at)
- **AdminAuditEntry** (id, admin_user_id, action, target_type, target_id, before_json, after_json, ip, user_agent, created_at, reason)
- **FeatureFlag** (id, key, description, scope, enabled, value_json, last_changed_by, last_changed_at)
- **KillSwitchEvent** (id, admin_user_id, switch_key, action [enabled/disabled], reason, lawyer_reference, created_at)
- **SystemConfig** (id, key, value, type, description, last_changed_by, last_changed_at, effective_from)
- **DataRequest** (id, subject_user_id, type [export/delete], status, requested_at, fulfilled_at, fulfilled_by_admin_id, notes)
- **AIProvider** (id, category, provider_key, is_primary, is_fallback, model_name, api_key_encrypted, endpoint_url, params_json, dpa_reference?, active, last_changed_by, last_changed_at)
- **AIUsageLog** (id, provider_id, category, request_count, tokens_used, cost_usd, success, latency_ms, created_at, failover_from_provider_id?)
- **Notification** (id, admin_user_id?, system_trigger?, audience_type, audience_filter_json, channels[], title_en, title_bn, body_en, body_bn, variables_used[], scheduled_at?, sent_at?, status, recipient_count, delivered_count, opened_count, cost_bdt)
- **NotificationDelivery** (id, notification_id, recipient_user_id, channel, status, delivered_at?, opened_at?, error?)
- **NotificationTemplate** (id, key, title_en, title_bn, body_en, body_bn, trigger_event, channels[], variables[], active, last_changed_by, last_changed_at)

---

## 6. Non-Functional Requirements

- **Performance:** all pages <1.5s on broadband.
- **Security:** all admin sessions require MFA; IP allowlist optional; full audit on every action.
- **Reliability:** admin portal can run independently of client APIs in degraded mode (read-only).
- **Backup:** admin portal state included in daily backups.
- **Browser support:** Chrome, Edge, Safari, Firefox — latest 2 versions.
- **Language:** English primary; no Bangla UI required (internal staff use English for consistency with logs/code).

---

## 7. Acceptance Criteria

The admin portal MVP is accepted when:

1. An admin can log in via email + password + MFA, with session timeout enforced.
2. Super Admin can view the dashboard and see live KPIs.
3. Ops Admin can search a user by phone, view full profile, suspend the account with reason, and see the action in the audit log.
4. Super Admin can change a pricing tier (e.g., Free 2 → 3 tenants) and the change is reflected in the client apps within 60 seconds, with full audit trail.
5. Compliance Admin can toggle the warnings kill-switch off, with reason + MFA confirmation, and the warning UI disappears across all client apps on next refresh.
6. Any admin can pull a full audit log filtered by user, action, or date.
7. System Config values can be edited and take effect immediately.
8. All admin actions appear in the AdminAuditEntry log with before/after diff.
9. No admin can edit a pricing tier, feature flag, or kill-switch without an audit log entry being written.
10. **AI Providers:** admin can swap chatbot LLM from Claude to GPT-4o, configure OpenAI as fallback, test connection (returns OK), save — change takes effect in next chatbot request within 60s.
11. **AI Providers:** attempting to select a non-BD-hosted OCR provider for NID extraction surfaces a DPA reference requirement before save.
12. **Notifications:** admin can compose bilingual notification, target "free-tier landlords with ≥2 tenants" segment, see reach count (412) and cost preview (~Tk 206), send via WhatsApp + in-app, view delivery progress in History tab.
13. **Notifications:** system-triggered templates (rent reminder, welcome, free-limit, etc.) are admin-editable for title/body/channels.

---

## 8. Phase Plan

| Phase | What ships |
|-------|-----------|
| **P0 (M4–6)** | Dashboard, Users, Pricing config, Feature flags, Kill-switches, **AI Providers (all 4 categories) with primary+fallback+test connection**, **Notifications composer + audience targeting + multi-channel + history**, Audit log, System config, Admin user management, Compliance basics |
| **P1 (M6–12)** | Analytics, Support tickets, Refund workflow, Data request queue, A/B experiments, Notification recurring schedules, AI provider cost-budget alerts |
| **P2 (M12+)** | Advanced security, IP allowlist, alerting, BI dashboards, Custom AI provider endpoints (Cohere, Mistral, future providers) |

---

## 9. Out of Scope

- White-label admin portals for B2B managers (use B2B Manager Tier inside main app instead).
- Real-time chat with end users (use WhatsApp Business directly).
- Built-in helpdesk system (integrate with external tool if needed at scale).
- Mobile-optimized admin portal (admins use desktop).
