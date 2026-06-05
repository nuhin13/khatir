---
id: T-012
epic: EPIC-15
title: Notification history page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007]
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

# T-012 · Notification history page (Next.js)

## 1. Feature goal
Table of sent/scheduled notifications with sent/delivered/opened counts, status, and a detail view showing per-recipient deliveries. Date filter. Super+ops.

## 2. Business logic
Table of sent/scheduled notifications with sent/delivered/opened counts, status, and a detail view showing per-recipient deliveries. Date filter. Super+ops.

## 3. What this task DOES
See feature goal. Next.js admin UI component per the description.

## 5. Files & changes
### Add
- app/(dashboard)/notifications/... ; components/admin/... ; test.
### Update
- sidebar "Notifications" → /notifications (if not linked).

## 6–10.
No DB; consumes notifications endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Notifications + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Tailwind-themed; Notun Din tokens

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core UI per description
- [x] Super+ops route guard
- [x] TanStack Query; loading/error/data states
- [x] Test (render + interaction)
- [x] eslint + tsc pass

## 12. Test plan
### Automated
- Core render tests
## 13. Acceptance criteria
- [x] UI works per goal; states; super+ops gate; tests pass.
## 14. Self-review
- [x] Tailwind tokens; super+ops; states complete
### Deviations from spec
- History lives at `/notifications/history` (the `/notifications` route is the
  composer, T-010) and gets its own super/ops-gated sidebar item. The list is
  reused from `GET /admin/api/notifications` (newest-first) with a client-owned
  `from`/`to` date window; the T-007 list endpoint is not server-paginated, so
  no cursor controls (unlike the audit viewer). Search/export columns from spec
  §4.5.2 are out of scope — the endpoint exposes no full-text or export route.
### Files touched (actual)
- `apps/admin/src/lib/api/notifications.ts` — added `NotificationDelivery` /
  `NotificationDetail` schemas + types, `fetchNotificationDetail`,
  date `NotificationFilters` + `notificationsPath`, filtered
  `notificationsQueryKey(filters)` + `notificationsQueryPrefix`,
  `notificationDetailQueryKey`.
- `apps/admin/src/components/admin/notification_history_table.tsx` — new.
- `apps/admin/src/app/(dashboard)/notifications/history/page.tsx` — new (server
  guard).
- `apps/admin/src/app/(dashboard)/notifications/history/history_client.tsx` —
  new (TanStack Query island).
- `apps/admin/src/components/admin/notification_composer.tsx` — switched
  invalidation to `notificationsQueryPrefix`.
- `apps/admin/src/app/(dashboard)/_nav.ts` — new "Notification history" item.
- `apps/admin/src/test/notification-history.test.tsx` — new (6 tests).
- `apps/admin/src/test/sidebar.test.tsx` — added "Notification history" to the
  live-pages set.
## 15. Notes
Table of sent/scheduled notifications with sent/delivered/opened counts, status, and a detail view showing per-recipient deliveries. Date filter. Super+ops.
