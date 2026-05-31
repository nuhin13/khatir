---
id: T-010
epic: EPIC-11
title: Sidebar navigation + coming-soon stubs
layer: admin
size: S
status: todo
preferred_agent: codex
depends_on: [T-008]
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
- [ ] all §3.1 nav items linked
- [ ] coming-soon page for unbuilt modules
- [ ] active link highlight
- [ ] role visibility per T-008
- [ ] tests: nav items render, active state
- [ ] tsc pass

## 12. Test plan
### Automated
- sidebar_test → all nav items; active highlight
### Manual QA
1. Navigate to each item; unbuilt → coming soon.

## 13. Acceptance criteria
- [ ] All sidebar items linked; coming-soon for unbuilt; tests pass.
## 14. Self-review
- [ ] Matches admin spec §3.1; role-aware
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Later EPICs (12–16) replace the coming-soon stubs one by one.
