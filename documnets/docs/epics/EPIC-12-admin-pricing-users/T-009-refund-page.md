---
id: T-009
epic: EPIC-12
title: Refund queue page (Next.js)
layer: admin
size: S
status: done
preferred_agent: codex
depends_on: [T-004]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Refund queue page (Next.js)

## 1. Feature goal
Simple table for finance staff to view and process pending refund requests.

## 2. Business logic
List of pending payment intents; each row: user, tier, amount, date; actions: Approve (reason) + Deny (reason). Finance+super.

## 3. What this task DOES
- /billing/refunds page; action dialogs. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/billing/refunds/page.tsx; test

## 6–10.
No DB; consumes refund endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/billing/refunds`
- Refund table + approve/deny dialogs

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] refund table (pending)
- [x] approve/deny dialogs (reason)
- [x] finance+super gate
- [x] test: renders, action fires
- [x] tsc pass

## 12. Test plan
### Automated
- refund_page renders; approve dialog fires
## 13. Acceptance criteria
- [x] Refund queue page; approve/deny; tests pass.
## 14. Self-review
- [x] Reason required; finance+super
### Deviations from spec
- The route is `/(dashboard)/billing/refunds` per spec; the sidebar `NAV_ITEMS`
  test's single-segment route regex (`/^\/[a-z-]+$/`, written when every live
  page was one segment) was widened to allow multi-segment absolute paths and
  the live-page allowlist gained "Refunds".
- Approve records an optional reason (audited); deny requires a non-blank reason
  (re-checked server-side by `RefundProcessSerializer` / `process_refund`).
### Files touched (actual)
- Add: `apps/admin/src/lib/api/refunds.ts`,
  `apps/admin/src/components/admin/refund_queue.tsx`,
  `apps/admin/src/app/(dashboard)/billing/refunds/page.tsx`,
  `apps/admin/src/test/refunds.test.tsx`
- Update: `apps/admin/src/app/(dashboard)/_nav.ts` (live finance-gated Refunds
  item), `apps/admin/src/test/sidebar.test.tsx` (route regex + live-page set)
## 15. Notes
- Simple for MVP. MFS integration trails.
