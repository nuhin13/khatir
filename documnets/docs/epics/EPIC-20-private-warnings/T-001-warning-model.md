---
id: T-001
epic: EPIC-20
title: Warning model + migration
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [EPIC-06.T-001]
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

# T-001 · Warning model + migration

## 1. Feature goal
Model a private warning issued by a landlord to their own tenant.

## 2. Business logic
Warning(lease FK, tenant FK, landlord FK, warning_type enum, reason text, issued_at, notice_ref PDF nullable, acknowledged_at nullable). Scope is intrinsically private — only the issuing landlord + that tenant relate to it. No global/shared structure.

## 3. What this task DOES
- warnings app; Warning model; WarningType enum; migration; admin; tests.

## 5. Files & changes
### Add
- khatir/warnings/{__init__,apps,models,enums}.py, migration, tests/factories
### Update
- settings register

## 6–10.
Creates warnings_warning. Reversible. No external. No flags (enforced at endpoint).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Warning model (lease/tenant/landlord FKs, type, reason, notice_ref)
- [ ] WarningType enum (late_rent, lease_violation, noise, other)
- [ ] migration reversible; admin
- [ ] tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_warning_create
## 13. Acceptance criteria
- [ ] Model; migration clean; tests + lint pass.
## 14. Self-review
- [ ] No shared/global structure; landlord+tenant only
### Deviations from spec
### Files touched (actual)
## 15. Notes
- There is intentionally NO field or relation that would let warnings be aggregated across landlords. Keep it strictly relational to one lease.
