---
id: T-001
epic: EPIC-19
title: Tenant-account link + tenant-scoped permissions
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-04.T-001, EPIC-02.T-002]
blocks: [T-002]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Tenant-account link + tenant-scoped permissions

## 1. Feature goal
Link a tenant-role User to their Tenant record and provide permissions so a tenant can read only their own lease/rent/receipts.

## 2. Business logic
Use/extend Tenant.linked_user_id (EPIC-04). A tenant User resolves to their Tenant record(s) via the active lease. `IsLinkedTenant` permission + a `tenant_for_user(user)` resolver. A tenant sees only data for leases where they're the tenant.

## 3. What this task DOES
- Tenant-account resolver + IsLinkedTenant permission + scoping helpers; tests (own vs others').

## 5. Files & changes
### Add
- tenants/tenant_account.py, permissions additions; tests/test_tenant_scope.py
### Update
- Tenant model link helper

## 6–10.
No new table (reuse linked_user_id) or a thin TenantAccount link if cleaner. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] tenant_for_user resolver (User → Tenant via active lease)
- [x] IsLinkedTenant permission
- [x] scoping: tenant sees only own lease/rent/receipts
- [x] tests: own ok, others' 404
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_tenant_resolves_own, test_cannot_see_others
## 13. Acceptance criteria
- [x] Tenant linking + strict scoping; tests + lint pass.
## 14. Self-review
- [x] No cross-tenant access possible
### Deviations from spec
- Reused `Tenant.linked_user` (EPIC-04) — no new table/`TenantAccount`. The
  resolver lives in `tenants/tenant_account.py` (module, not model).
- Tenant-scoping helpers were placed in `tenant_account.py` (free functions)
  rather than a Lease `for_user(tenant)` branch, so the tenant read path stays
  one explicit, auditable place separate from the landlord/manager queryset.
  The actual `/me/` endpoints (T-002) consume these.
### Files touched (actual)
- Add: `apps/api/khatir/tenants/tenant_account.py`
- Add: `apps/api/khatir/tenants/tests/test_tenant_scope.py`
- Update: `apps/api/khatir/tenants/permissions.py` (`IsLinkedTenant`)
## 15. Notes
- A tenant may have had multiple leases over time — scope to leases where they are/were the tenant. Current view = active lease.
