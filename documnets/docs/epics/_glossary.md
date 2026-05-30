# Glossary

> Shared vocabulary. When a task or doc uses one of these terms, this is what it means. Keeps agents from inventing divergent names.

| Term | Meaning |
|------|---------|
| **DMP form** | Dhaka Metropolitan Police tenant registration form (CIMS). The wedge feature — generated as a print-ready PDF. |
| **Wedge** | The single highest-value feature that drives initial adoption: DMP form via NID OCR. |
| **NID** | National ID card (Bangladesh). Sensitive personal data — encrypted, BD-hosted, masked. |
| **OCR** | Optical character recognition — extracting NID fields from a photo. |
| **EC API** | Election Commission "Matched/Not Matched" identity verification. P1. Never Porichoy (severed 2024). |
| **Rent request** | A landlord-initiated ask for a tenant to pay; delivered via WhatsApp web-link or in-app. |
| **Web-link / tenant web-link** | A no-install web page (`/r/:token`) where a tenant submits payment proof. Served by Django. |
| **Payment proof** | Tenant-submitted evidence of payment (bKash txn id, screenshot, photo, note). |
| **Rent schedule** | Auto-generated monthly rent expectation per lease. |
| **Free tier** | First 2 tenants, full features except NID verification, ৳0. |
| **Role shell** | The role-specific bottom-nav container in the Flutter app (landlord/manager/tenant). |
| **Manager** | B2B user managing multiple owners' portfolios. |
| **Caretaker / darwan** | Building gatekeeper. P2 visitor-logging role. |
| **Warning** | Private landlord→tenant factual notice. Never public. P1. |
| **History flag** | Structured factual lease-tied reputation entry. Consent-gated. P2. |
| **Kill-switch** | Admin control to instantly disable a reputation/free-text/public feature. |
| **Feature flag** | DB-backed toggle controlling whether a feature is live, per scope. |
| **AI gateway** | FastAPI microservice abstracting LLM/OCR/ASR/lease providers. EPIC-14. |
| **AI provider** | A configurable backend for chat/voice/ocr/lease (OpenAI, Claude, Verbex, etc.), admin-swappable. |
| **SystemConfig** | DB key-value table of admin-tunable business values (limits, cadences, fees). |
| **for_user scope** | The mandatory manager method enforcing row-level multi-tenancy. |
| **Audit entry** | A logged record of any write to personal/sensitive data. |
| **Notun Din** | The locked visual aesthetic (sage/rose/butter/cream). |
| **Epic** | A complete shippable feature, not time-boxed. |
| **Task** | One scoped unit of work inside an epic, fully specified for autonomous execution. |
| **Peer review** | Review of a task by a *different* AI agent than the implementer. |
| **Handoff** | Passing a task between agents (or to human) via the task file + git, never via memory. |
| **Notun Din tokens** | The color/type/radius design tokens in `packages/design-tokens/`. |
| **Phase** | MVP / P1 / P2 / P3 — when an epic is built. |
