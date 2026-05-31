---
id: T-002
epic: EPIC-09
title: Dashboard API endpoint
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-001]
blocks: [T-004]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Dashboard API endpoint

## 1. Feature goal
One endpoint returning all dashboard metrics in a single call.

## 2. Business logic
GET /dashboard with optional months param (default from config). Owner-scoped. Cached briefly (60s) to avoid hammering on open.

## 3. What this task DOES
- Endpoint calling T-001 selectors; short cache; permissions; tests.

## 5. Files & changes
### Add
- dashboard/views.py, serializers.py, urls.py, tests/test_dashboard_api.py
### Update
- config/urls.py

## 6. Database changes
None.
## 7. API changes
| GET | /api/v1/dashboard?months=6 | Bearer | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] endpoint calls selectors
- [ ] months param + config default
- [ ] 60s cache
- [ ] owner-scoped + permission
- [ ] tests: response shape, scoped, months param
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_dashboard_response, test_scoped, test_months_param
### Manual QA
1. GET /api/v1/dashboard → all metrics present.

## 13. Acceptance criteria
- [ ] Dashboard endpoint returns all metrics; scoped + cached; tests + lint pass.

## 14. Self-review
- [ ] Cached; for_user
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Cache per user (not global). Short TTL to keep numbers fresh enough.
