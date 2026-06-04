---
id: T-004
epic: EPIC-15
title: Delivery tracking (per-recipient)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Delivery tracking (per-recipient)

## 1. Feature goal
Update NotificationDelivery status/delivered_at on send success/failure. Opened tracking: for web links (EPIC-07 receipts) use a tracking pixel or link parameter. Tests.

## 2. Business logic
Update NotificationDelivery status/delivered_at on send success/failure. Opened tracking: for web links (EPIC-07 receipts) use a tracking pixel or link parameter. Tests.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- Relevant backend files per layer; tests.

## 6–10.
DB: as described. Admin audit on writes. Super+ops role gate. No external services (uses NotificationSender). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation
- [x] Admin audit (EPIC-11 T-002 writer)
- [x] Tests (eager Celery where applicable; mocked sender)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per description
## 13. Acceptance criteria
- [x] Feature works per goal; audited; tests + lint pass.
## 14. Self-review
- [x] Audited; follows admin conventions; Celery eager in tests
### Deviations from spec
The success/failure status + delivered_at transitions for the initial send were
already implemented by T-003's deliver_to_recipient (in-app/email -> delivered;
remote channels -> sent). T-004 adds the *post-send* transitions that were
deferred there: (1) an open beacon (1x1 GIF tracking pixel at
/n/<token>/open.gif) that marks a delivery `opened`; (2) a provider delivery
webhook (POST /n/<token>/delivered) that advances a remote `sent` row to
`delivered`. Both are scoped by a signed, tamper-evident open-token
(notifications/tracking.py, dedicated salt; non-expiring Signer since a late
open is still valid telemetry) rather than admin auth — the token is the
capability, mirroring the EPIC-07 rent link-token pattern. State transitions
(mark_opened / confirm_delivered in tasks.py) are idempotent under
select_for_update so duplicate webhook retries or pixel reloads never
double-count; an open from `sent` backfills delivered_count exactly once. No
admin-audit writer is wired: these endpoints are public recipient/provider
callbacks, not admin writes (admin audit applies to the compose/template writes
in T-002/T-007/T-008, already covered). No model/migration change — the
opened_at / opened_count fields already exist on the T-001 schema.
### Files touched (actual)
- apps/api/khatir/notifications/tracking.py (signed open-token: make_token/resolve_token/beacon_path)
- apps/api/khatir/notifications/tasks.py (mark_opened + confirm_delivered idempotent transitions)
- apps/api/khatir/notifications/web_views.py (open_beacon pixel view + delivery_webhook)
- apps/api/khatir/notifications/web_urls.py (public /n/<token>/... routes)
- apps/api/config/urls.py (mount notifications.web_urls at root)
- apps/api/khatir/notifications/tests/test_tracking.py (20 tests: token, beacon, webhook, transitions)
## 15. Notes
Update NotificationDelivery status/delivered_at on send success/failure. Opened tracking: for web links (EPIC-07 receipts) use a tracking pixel or link parameter. Tests.
