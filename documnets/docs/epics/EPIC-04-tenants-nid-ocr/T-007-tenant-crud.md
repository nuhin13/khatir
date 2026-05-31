---
id: T-007
epic: EPIC-04
title: Tenant CRUD + family members + for_user
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, EPIC-03.T-002]
blocks: [T-008, T-014]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Tenant CRUD + family members + for_user

## 1. Feature goal
Create/read/update tenants (from reviewed fields) under a unit, with nested family members, scoped to the owner, NID encrypted, audited.

## 2. Business logic
Create takes reviewed fields + optional photo_ref (from OCR) → encrypts NID → persists. for_user via the tenant's unit→building→owner chain. Audit on create/update. Masked serialization by default.

## 3. What this task DOES
- Tenant serializers (masked), services (create_tenant, update), family nested write, for_user manager, permissions, endpoints, audit. Tests incl. encryption + scoping + cross-user 404.

## 5. Files & changes
### Add
- tenants/{serializers,services,managers,permissions,views,urls}.py, tests/test_tenant_api.py
### Update
- config/urls.py

## 6. Database changes
Writes tenants + family. No schema change.

## 7. API changes
| Method | Path | Auth | Status |
| POST | /api/v1/tenants | owner | 201 |
| GET | /api/v1/tenants/{id} | owner | 200 |
| GET | /api/v1/units/{id}/tenants | owner | 200 |
| PATCH | /api/v1/tenants/{id} | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] Tenant serializer (masked default)
- [ ] create_tenant service (encrypt NID, attach photo_ref, family)
- [ ] for_user via unit→building→owner
- [ ] permissions
- [ ] endpoints + urls
- [ ] audit on create/update
- [ ] Tests: create/encrypt/masked, family, scoping, cross-user 404
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create_encrypts_masks, test_family_nested, test_for_user_scope, test_cross_user_404
### Manual QA
1. Create tenant under a unit; list unit tenants.

## 13. Acceptance criteria
- [ ] Tenant CRUD scoped + encrypted + audited; tests + lint pass.

## 14. Self-review
- [ ] for_user on all reads; NID never plaintext in API/logs
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- for_user chain: Tenant → unit → building → owner. Manager via owner links.
