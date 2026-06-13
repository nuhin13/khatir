---
id: T-008
epic: EPIC-04
title: Free-tier counter hook (count tenants)
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Free-tier counter hook (count tenants)

## 1. Feature goal
Expose the landlord's current tenant count + free-limit status so the UI can show "1/2 free" and EPIC-10 can enforce the limit.

## 2. Business logic
Free limit from `free_tier_tenant_limit` SystemConfig (default 2). This task provides the count + a soft signal; hard enforcement (blocking creation / requiring upgrade) is EPIC-10.

## 3. What this task DOES
- A selector / endpoint field: tenants_used, free_limit, is_over_free.
- Surface in profile/me or a small `/api/v1/usage` endpoint. Tests on counting.

## 5. Files & changes
### Add
- usage selector + tests
### Update
- expose in /usage or /auth/me

## 6. Database changes
None (count query).
## 7. API changes
Adds usage fields (tenants_used, free_limit, is_over_free).
## 8. UI changes
No UI (consumed by More/plan + EPIC-10).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] tenant count selector (per owner, non-deleted)
- [x] free_limit from SystemConfig
- [x] is_over_free signal
- [x] exposed (usage endpoint or me)
- [x] Tests: count, limit, over-flag
- [x] ruff clean

## 12. Test plan
### Automated
- test_count, test_over_free_when_exceeds
### Manual QA
1. Add 3rd tenant → is_over_free true (not blocked yet).

## 13. Acceptance criteria
- [x] Accurate count + free status exposed; tests pass.

## 14. Self-review
- [x] Limit from config not hardcoded
### Deviations from spec
- Exposed via a dedicated `GET /api/v1/usage` (allowed by §5 "expose in /usage or /auth/me"), not on `/auth/me`, since the counter is landlord/manager-scoped (role-gated) while `/auth/me` is generic session bootstrap.
- Added a core data migration (`core/0005_seed_free_tier_config.py`) seeding `free_tier_tenant_limit=2`; updated `core/tests/test_config.py::test_get_config_typed_int` to upsert (it reused the same literal key, which now collides with the seed).
### Files touched (actual)
- Add: `khatir/tenants/usage.py`, `khatir/tenants/tests/test_usage.py`, `khatir/core/migrations/0005_seed_free_tier_config.py`
- Update: `khatir/tenants/{views,serializers,urls}.py`, `khatir/core/tests/test_config.py`

## 15. Notes for the implementing agent
- Do NOT block creation here — EPIC-10 owns enforcement. This is the counter only.
