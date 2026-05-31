---
id: T-012
epic: EPIC-11
title: Seed first AdminUser (setup script)
layer: backend
size: XS
status: todo
preferred_agent: codex
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-012 · Seed first AdminUser (setup script)

## 1. Feature goal
A one-time setup script to create the first super-admin account so the portal is immediately usable after deploy.

## 2. Business logic
Django management command `create_super_admin` (email, name, generates a temp password, prints TOTP setup QR URL). Safe to run once; idempotent (skip if email exists). Audit the creation.

## 3. What this task DOES
- management command; TOTP setup output; tests (dry-run idempotent).

## 5. Files & changes
### Add
- admin_portal/management/commands/create_super_admin.py; test

## 6. Database changes
Creates one AdminUser row.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] create_super_admin command
- [ ] prints temp password + TOTP setup URL
- [ ] idempotent (skip if exists)
- [ ] audit the creation
- [ ] test (dry-run)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_command_creates_user, test_idempotent
### Manual QA
1. python manage.py create_super_admin → prints creds; login works.

## 13. Acceptance criteria
- [ ] Setup script creates super admin; idempotent; test passes.
## 14. Self-review
- [ ] Temp password printed once; TOTP URL shown; audited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Print the TOTP provisioning URL (otpauth://...) so the admin can scan it into Google Authenticator / Authy. Never log passwords after the initial print.
