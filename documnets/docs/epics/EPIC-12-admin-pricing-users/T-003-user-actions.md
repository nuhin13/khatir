---
id: T-003
epic: EPIC-12
title: User search + detail + actions endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-11.T-001]
blocks: [T-007, T-008]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · User search + detail + actions endpoints

## 1. Feature goal
Support operations staff searching and managing user accounts.

## 2. Business logic
GET /admin/api/users: search by phone/name/ID/masked-NID, paginated. GET /{id}: full profile + subscription + usage + recent audit trail. POST /{id}/suspend (reason required) → is_active=false + JWT blacklist all tokens. POST /{id}/reactivate. POST /{id}/upgrade-subscription. All admin audited. Ops+super role.

## 3. What this task DOES
- Search, detail, suspend, reactivate, upgrade-subscription endpoints; JWT invalidation on suspend; audit; tests.

## 5. Files & changes
### Add
- admin_portal/user_views.py, serializers, tests/test_user_admin.py
### Update
- admin_portal/urls.py

## 6. Database changes
Writes User.is_active; Subscription.
## 7. API changes
| GET | /admin/api/users | ops/super | 200 paginated |
| GET | /admin/api/users/{id} | ops/super | 200 |
| POST | /admin/api/users/{id}/suspend | ops/super | 200 |
| POST | /admin/api/users/{id}/reactivate | ops/super | 200 |
| POST | /admin/api/users/{id}/upgrade-subscription | ops/super | 200 |

## 8. UI changes
No UI (T-007/T-008).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] search endpoint (phone/name/id/masked-nid)
- [ ] detail (profile + subscription + usage + audit trail)
- [ ] suspend (is_active=false + JWT blacklist + reason)
- [ ] reactivate
- [ ] upgrade-subscription (manual override)
- [ ] admin audit all actions
- [ ] ops+super role gate
- [ ] Tests: search, suspend+invalidate, reactivate, audit
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_search, test_suspend_invalidates_jwt, test_reactivate, test_audit
### Manual QA
1. Suspend a user → they can't log in. Reactivate → login works.

## 13. Acceptance criteria
- [ ] User search + actions; JWT invalidated on suspend; audited; tests + lint pass.

## 14. Self-review
- [ ] Reason required for suspend; JWT blacklisted; audited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- JWT blacklist: increment a user "token version" or blacklist all outstanding refresh tokens for that user. Keep it simple but effective.
