# EPIC-15 · Admin — Notifications

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-11
**Tasks:** 14 · **External services:** WhatsApp Business API, SMS gateway, email provider

---

## Business goal
Let staff compose and send targeted, multi-channel, bilingual notifications, with delivery history and reusable system templates — including the rent-reminder and receipt templates that EPIC-07 already uses.

## Scope
**In:** Notification composer (audience targeting, channels, bilingual title+body, variables, schedule: now/scheduled/recurring, reach+cost preview). Delivery engine (Celery) + per-recipient tracking. History + templates tab (auto-triggered system templates editable). EPIC-01's NotificationSender extended with templates.
**Out:** SMS/WhatsApp billing reconciliation; push notifications (in-app only for now).

## Dependencies
EPIC-11 (admin shell). EPIC-01 (NotificationSender re-used + extended). EPIC-07 (rent-reminder + receipt templates live here).

## Data-model changes
- `Notification`: sender FK AdminUser, audience_type, audience_filter, channels, title_en/bn, body_en/bn, schedule_type, scheduled_at, status, sent/delivered/opened counts, cost_estimate.
- `NotificationDelivery`: notification FK, user FK, channel, status, delivered_at, opened_at, error.
- `NotificationTemplate`: key, trigger_event, channels, title/body bilingual, variables, active.

## API surface
- `POST /admin/api/notifications` (compose+schedule), `GET` (history), `GET /{id}` + deliveries.
- `GET/POST/PATCH /admin/api/notification-templates`.
- `POST /admin/api/notifications/{id}/send-test`.

## Acceptance criteria
- [ ] Admin can compose a notification with audience targeting + bilingual content + schedule and send or schedule it.
- [ ] Delivery engine sends per channel + tracks per-recipient delivery status.
- [ ] System templates (rent reminder, welcome, receipt) are editable via admin.
- [ ] EPIC-07 rent reminders use the template system.
- [ ] History shows sent/delivered/opened counts.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Notification + Delivery + Template models | backend | M | EPIC-00.T-005 |
| T-002 | Notification compose + schedule service | backend | M | T-001, EPIC-01.T-004 |
| T-003 | Notification delivery Celery task | backend | M | T-002, EPIC-00.T-006 |
| T-004 | Delivery tracking (per-recipient) | backend | S | T-003 |
| T-005 | System templates seed (rent-reminder, receipt, welcome) | backend | S | T-001 |
| T-006 | Retrofit EPIC-07 reminders to use template system | backend | S | T-005, EPIC-07.T-008 |
| T-007 | Admin notifications CRUD endpoints | backend | M | T-001, EPIC-11.T-002 |
| T-008 | Admin templates CRUD endpoints | backend | S | T-001 |
| T-009 | Seed notifications config | backend | XS | EPIC-00.T-005 |
| T-010 | Notification composer page (Next.js) | admin | M | T-007, EPIC-11.T-008 |
| T-011 | Audience + channel selector widgets | admin | M | T-010 |
| T-012 | Notification history page (Next.js) | admin | M | T-007 |
| T-013 | Notification templates page (Next.js) | admin | M | T-008 |
| T-014 | Reach + cost preview widget | admin | S | T-007 |
