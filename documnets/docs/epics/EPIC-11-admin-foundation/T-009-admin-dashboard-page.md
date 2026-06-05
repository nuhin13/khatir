---
id: T-009
epic: EPIC-11
title: Platform dashboard page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-005, T-008]
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

# T-009 · Platform dashboard page (Next.js)

## 1. Feature goal
The admin home: platform KPI tiles (users, properties, revenue, DMP forms), an activity feed (recent audit entries), and a health status block.

## 2. Business logic
Fetches /admin/api/dashboard; TanStack Query; displays KPI cards, activity feed (last 20 audit entries), health tiles. Auto-refreshes every 60s.

## 3. What this task DOES
- /dashboard page; KPI cards; activity feed; health; auto-refresh; states. Test.

## 5. Files & changes
### Update
- app/(dashboard)/dashboard/page.tsx (replace placeholder)
### Add
- components/admin/{kpi_card,activity_feed,health_tile}.tsx; test

## 6–10.
No DB; consumes /admin/api/dashboard; surface admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `ui/KhatirAdmin.jsx` dashboard section + `04_Admin_Portal_Khatir.md`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/dashboard`
- KPI tiles, activity feed, health; Notun Din Tailwind tokens
- States: loading / error / data; auto-refresh

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] KPI tiles (users/properties/revenue/forms)
- [x] activity feed (recent admin audit entries)
- [x] health status tiles (app/DB/Redis)
- [x] TanStack Query with 60s refetch
- [x] loading + error states
- [x] tests (render KPIs + activity)
- [x] eslint + tsc pass

## 12. Test plan
### Automated
- dashboard_page renders KPIs + activity feed
### Manual QA
1. Admin dashboard shows live numbers.

## 13. Acceptance criteria
- [x] Dashboard page shows real platform KPIs; auto-refreshes; tests pass.
## 14. Self-review
- [x] Replaces EPIC-00 placeholder; TanStack Query; tokens
### Deviations from spec
- Activity feed: the committed T-005 `/admin/api/dashboard` payload carries only
  KPIs + live `health` (no audit list; the audit list API is T-011, not yet
  done). The data layer (`lib/api/dashboard.ts`) therefore models
  `recent_activity` as an optional array defaulting to `[]`; `ActivityFeed`
  renders its empty state until that field is populated server-side — no UI
  change needed when it lands.
- KPI tiles surface the real T-005 metrics (total_users, active_landlords,
  properties + occupied/total units, rent collected this-month/all-time, DMP
  forms, active subscriptions) rather than the prototype's MRR/churn mock values
  (no such selectors exist).
- Health panel maps the payload's app/database/cache statuses to token-coloured
  chips (ok→sage, degraded→butter, down→danger).
### Files touched (actual)
- Update: apps/admin/src/app/(dashboard)/dashboard/page.tsx (real client page,
  TanStack Query 60s refetch, loading/error/data states)
- Add: apps/admin/src/lib/api/dashboard.ts (zod schema + fetchDashboard);
  apps/admin/src/components/admin/{kpi_card,activity_feed,health_tile}.tsx;
  apps/admin/src/test/dashboard.test.tsx

## 15. Notes for the implementing agent
- Replaces the EPIC-00 T-009 placeholder dashboard page.
