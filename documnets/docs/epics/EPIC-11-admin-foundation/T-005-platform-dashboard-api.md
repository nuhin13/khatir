---
id: T-005
epic: EPIC-11
title: Platform dashboard API endpoint
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-009]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Platform dashboard API endpoint

## 1. Feature goal
Platform-wide KPIs for the admin dashboard: total users, properties, rent collected, DMP forms generated, active subscriptions, health.

## 2. Business logic
Aggregates across all users (no for_user scoping — admin sees everything). Cached 5 min. Requires admin auth (ops/super).

## 3. What this task DOES
- Platform KPI selectors + endpoint. Tests.

## 5. Files & changes
### Add
- admin_portal/dashboard.py, views/urls; tests/test_platform_dashboard.py

## 6–10.
No DB change; consumes multiple app tables; no external; no flags.

## 7. API changes
| GET | /admin/api/dashboard | admin | 200 |

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] total_users, active_landlords, total_properties, total_units, occupied_units
- [ ] total_rent_collected (all time + this month)
- [ ] dmp_forms_generated, active_subscriptions
- [ ] 5-min cache
- [ ] admin auth (ops/super)
- [ ] Tests: KPIs present, scoped to admin
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_platform_kpis_present, test_admin_only
### Manual QA
1. GET /admin/api/dashboard → all KPIs.

## 13. Acceptance criteria
- [ ] Platform KPIs endpoint; cached; admin-only; tests + lint pass.
## 14. Self-review
- [ ] Cached; no N+1; admin-only
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Health field: simple app status + DB/Redis reachability.
