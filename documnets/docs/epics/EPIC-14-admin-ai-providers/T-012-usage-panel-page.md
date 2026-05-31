---
id: T-012
epic: EPIC-14
title: AI usage panel page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-009]
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

# T-012 · AI usage panel page (Next.js)

## 1. Feature goal
Usage dashboard showing AI call volumes, token consumption, costs, and failover events per provider/category.

## 2. Business logic
Table + charts: requests/day by category, cost accumulation, error rate, recent failover events. TanStack Query. Super+ops.

## 3. What this task DOES
- /ai-providers/usage page (or tab within /ai-providers); usage table + mini charts; date filter. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/ai-providers/usage/page.tsx; test

## 6–10.
No DB; consumes /admin/ai-usage; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §AI Usage
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/ai-providers/usage`
- Usage table + charts + failover log

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] usage table (category, requests, tokens, cost, error_rate)
- [ ] date filter
- [ ] recent failover events
- [ ] super+ops gate
- [ ] TanStack Query; states
- [ ] test: renders usage table
- [ ] tsc pass

## 12. Test plan
### Automated
- usage_panel renders table
## 13. Acceptance criteria
- [ ] AI usage panel; table + filter; tests pass.
## 14. Self-review
- [ ] Costs visible; failover events shown
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Cost in USD (from AIUsageLog); show a running total for the billing period.
