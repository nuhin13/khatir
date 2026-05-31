---
id: T-009
epic: EPIC-11
title: Platform dashboard page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-005, T-008]
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
- [ ] KPI tiles (users/properties/revenue/forms)
- [ ] activity feed (recent admin audit entries)
- [ ] health status tiles (app/DB/Redis)
- [ ] TanStack Query with 60s refetch
- [ ] loading + error states
- [ ] tests (render KPIs + activity)
- [ ] eslint + tsc pass

## 12. Test plan
### Automated
- dashboard_page renders KPIs + activity feed
### Manual QA
1. Admin dashboard shows live numbers.

## 13. Acceptance criteria
- [ ] Dashboard page shows real platform KPIs; auto-refreshes; tests pass.
## 14. Self-review
- [ ] Replaces EPIC-00 placeholder; TanStack Query; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Replaces the EPIC-00 T-009 placeholder dashboard page.
