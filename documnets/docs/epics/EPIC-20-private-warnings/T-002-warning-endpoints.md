---
id: T-002
epic: EPIC-20
title: Warning issue + list endpoints (scoped + kill-switch)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-13.T-002]
blocks: [T-003, T-005, T-007, T-009, T-010]
external_services: []
feature_flags: [warnings_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Warning issue + list endpoints (scoped + kill-switch)

## 1. Feature goal
Issue + list warnings — gated by the `warnings_feature` kill-switch and strictly scoped to the issuing landlord's own tenants.

## 2. Business logic
Kill-switch gate first: if `warnings_feature` off → 403 feature_disabled (and UI hides it). Issue: create Warning for the landlord's own lease/tenant; audit. List: only the requesting landlord's own warnings for that lease. Never any cross-landlord read.

## 3. What this task DOES
- Issue + list endpoints; kill-switch gate; for_user scope (landlord's own); audit; tests.

## 5. Files & changes
### Add
- warnings/{serializers,services,views,urls}.py; tests/test_warning_api.py
### Update
- config/urls.py

## 6. Database changes
Writes Warning.
## 7. API changes
| POST | /api/v1/leases/{id}/warnings | owner + warnings_feature | 201 |
| GET | /api/v1/leases/{id}/warnings | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
- warnings_feature (kill-switch; off → 403)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] warnings_feature kill-switch gate (off → feature_disabled)
- [ ] issue (landlord's own lease/tenant only) + audit
- [ ] list (own only — never cross-landlord)
- [ ] for_user scope via lease→landlord
- [ ] Tests: issue, list scoped, kill-switch off blocks, cross-landlord 404
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_issue, test_list_own_only, test_killswitch_off, test_cross_landlord_404
### Manual QA
1. Issue a warning → appears in own list. Toggle kill-switch off → feature gone.

## 13. Acceptance criteria
- [ ] Issue + list, kill-switch gated, strictly scoped, audited; tests + lint pass.
## 14. Self-review
- [ ] Kill-switch enforced; no cross-landlord path; audited
### Deviations from spec
### Files touched (actual)
## 15. Notes
- The kill-switch check should be the very first thing the endpoint does. This feature ships OFF-able by design.
