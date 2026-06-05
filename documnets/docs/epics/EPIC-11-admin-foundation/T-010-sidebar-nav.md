---
id: T-010
epic: EPIC-11
title: Sidebar navigation + coming-soon stubs
layer: admin
size: S
status: done
preferred_agent: codex
depends_on: [T-008]
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

# T-010 · Sidebar navigation + coming-soon stubs

## 1. Feature goal
Complete the sidebar with all nav items per admin spec §3.1, each linking to its page (or a "coming soon" stub for not-yet-built modules).

## 2. Business logic
Sidebar items: Dashboard, Users, Pricing, Features, Kill-switch, Notifications, AI Providers, Compliance, System, Admin Users, Analytics, Security. Role-aware visibility (T-008 handles this). Unbuilt pages → clean "coming soon" page with nav context.

## 3. What this task DOES
- Sidebar items wired to routes; coming-soon page component; tests.

## 5. Files & changes
### Add
- app/(dashboard)/coming-soon/page.tsx (reusable)
### Update
- nav config in shell to point to correct routes

## 6–10.
No DB; admin 🟣; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] all §3.1 nav items linked
- [x] coming-soon page for unbuilt modules
- [x] active link highlight
- [x] role visibility per T-008
- [x] tests: nav items render, active state
- [x] tsc pass

## 12. Test plan
### Automated
- sidebar_test → all nav items; active highlight
### Manual QA
1. Navigate to each item; unbuilt → coming soon.

## 13. Acceptance criteria
- [x] All sidebar items linked; coming-soon for unbuilt; tests pass.
## 14. Self-review
- [x] Matches admin spec §3.1; role-aware
### Deviations from spec
- The full sidebar (all §3.1 nav items + routes + role visibility + active-link
  highlight) and the reusable coming-soon stub were already delivered by T-008's
  shell work: `_nav.ts` (NAV_ITEMS covering all 13 spec entries incl. the
  broken-out Kill-switch page, `navForRole`), `components/features/sidebar.tsx`
  (active highlight via `usePathname`, "Soon" badge for `comingSoon` items),
  and `components/features/coming-soon.tsx`. Every unbuilt module page under
  `app/(dashboard)/<module>/page.tsx` renders `<ComingSoon title=…/>`.
- Coming-soon is a shared component reused by each module route rather than a
  single `app/(dashboard)/coming-soon/page.tsx`, so each stub keeps its own
  route/title and nav context (cleaner than one shared route + redirects).
- This task therefore adds the T-010-specific test coverage that T-008 left
  open: nav-route linking, coming-soon badge presence, active-link highlight,
  and ComingSoon render. No production code changes were needed.
### Files touched (actual)
- Update: apps/admin/src/test/sidebar.test.tsx (NAV_ITEMS §3.1 coverage,
  distinct-route linking, coming-soon flags + "Soon" badge, link hrefs)
- Add: apps/admin/src/test/sidebar-active.test.tsx (active-link highlight,
  child-route stays active); apps/admin/src/test/coming-soon.test.tsx
  (heading + placeholder render)
## 15. Notes
- Later EPICs (12–16) replace the coming-soon stubs one by one.
