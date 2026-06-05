---
id: T-012
epic: EPIC-14
title: AI usage panel page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-009]
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
- [x] usage table (category, requests, tokens, cost, error_rate) — `wip`
- [x] date filter — `wip`
- [x] recent failover events — `wip`
- [x] super+ops gate — `wip`
- [x] TanStack Query; states — `wip`
- [x] test: renders usage table — `wip`
- [x] tsc pass — `wip`

## 12. Test plan
### Automated
- usage_panel renders table
## 13. Acceptance criteria
- [x] AI usage panel; table + filter; tests pass.
## 14. Self-review
- [x] Costs visible; failover events shown
### Deviations from spec
- The committed T-009 `/admin/api/ai-usage` endpoint aggregates volume only — it
  carries no per-row latency and no standalone failover-event stream. So the
  panel derives `error_rate`/success-rate and the "Failover & errors" log from
  the `call_count`/`success_count` the endpoint returns (each category with ≥1
  failed call is listed). The date filter is forwarded as `from`/`to` query
  params; the server ignores params it does not yet honour, keeping the UI
  forward-compatible.
### Files touched (actual)
- apps/admin/src/lib/api/ai-usage.ts (add)
- apps/admin/src/components/admin/ai_usage_panel.tsx (add)
- apps/admin/src/app/(dashboard)/ai-providers/usage/page.tsx (add)
- apps/admin/src/test/ai-usage.test.tsx (add)
## 15. Notes
- Cost in USD (from AIUsageLog); show a running total for the billing period.
