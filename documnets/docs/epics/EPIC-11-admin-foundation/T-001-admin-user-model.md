---
id: T-001
epic: EPIC-11
title: AdminUser model + enums + migration
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-002, T-003, T-004, T-012]
external_services: []
feature_flags: []
started_at: 2026-06-04completed_at: 2026-06-04executed_by: claudereviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · AdminUser model + enums + migration

## 1. Feature goal
Create the `admin_portal` app with an `AdminUser` model — **completely separate** from the customer-facing `User` model.

## 2. Business logic
Per schema Domain 8. AdminUser: email (unique, login), name, password_hash (Argon2/bcrypt), totp_secret_enc (encrypted, nullable until MFA setup), AdminRole enum (super/ops/finance/compliance/support), scope jsonb, disabled bool, last_login_at. Inherits TimeStampedModel, NOT AbstractBaseUser (it's our own auth, not Django's).

## 3. What this task DOES
- admin_portal app; AdminUser model; AdminRole enum; admin Django admin (for bootstrapping only); migration; factories + tests.

## 5. Files & changes
### Add
- khatir/admin_portal/{__init__,apps,models,enums}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
Creates admin_portal_adminuser. Reversible.
## 7. API changes
None.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] AdminUser (email unique, password hashed, totp_secret_enc, role, disabled)
- [ ] AdminRole enum matches spec
- [ ] TOTP secret encrypted at rest (core.encryption)
- [ ] migration reversible
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_admin_user_create, test_disabled_flag, test_totp_secret_encrypted
### Manual QA
1. Create AdminUser programmatically.

## 13. Acceptance criteria
- [ ] AdminUser model per spec; separate from User; migration clean; tests + lint pass.

## 14. Self-review
- [ ] Completely separate from accounts.User; TOTP encrypted
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use Argon2 (password-hashers) or bcrypt for password hashing — NOT MD5/SHA1. TOTP secret encrypted via core.encryption.
