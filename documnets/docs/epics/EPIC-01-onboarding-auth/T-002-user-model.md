---
id: T-002
epic: EPIC-01
title: accounts app + custom User model
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-003]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · accounts app + custom User model

## 1. Feature goal
Create the `accounts` Django app and the custom `User` model where the phone number is the login identity (no username/password-first design), establishing `AUTH_USER_MODEL` before any other app migrates.

## 2. Business logic
Per `06_database_schema.md` Domain 1: one `User` table for all human roles; `phone` unique (E.164); `role` enum; `language` enum (bn default); no password requirement (auth is OTP→JWT). **Critical Django ordering:** `AUTH_USER_MODEL` must be set and migrated before any model references the user, or migrations become painful. Since EPIC-00 created no domain models, we are safe to introduce it now as the first domain migration.

## 3. What this task DOES
- `accounts` app under `khatir/`.
- Custom `User(AbstractBaseUser, PermissionsMixin)` with manager (`create_user`, `create_superuser`), `phone` as `USERNAME_FIELD`, fields per schema (phone, role, name, language, is_active, is_staff, last_login_at), inheriting timestamps.
- `Role` + `Language` enums in `accounts/enums.py` (matching `enums.md`).
- Set `AUTH_USER_MODEL = "accounts.User"` in settings.
- Django admin registration for `User` (masked phone display ok).
- Initial migration.
- `for_user`-style manager not needed on User itself, but document the pattern stub.
- Tests: create_user/superuser, phone uniqueness, enum defaults.

## 4. What this task does NOT do
- No OTP, no JWT, no endpoints (T-003+).
- No role chooser/shells (EPIC-02). `role` defaults to `landlord` for now but is set properly in EPIC-02.

## 5. Files & changes
### Add
- `apps/api/khatir/accounts/__init__.py`, `apps.py`, `models.py`, `enums.py`, `managers.py`, `admin.py`
- `apps/api/khatir/accounts/migrations/0001_initial.py`
- `apps/api/khatir/accounts/tests/{test_models,factories}.py`
### Update
- `config/settings/base.py` — register `khatir.accounts`, set `AUTH_USER_MODEL`
### Delete
- none

## 6. Database changes
- Creates `accounts_user` table (the custom user). Domain 1 of the schema.
- Reversible. **Must be the first domain migration** (no prior model references the user).

## 7. API changes
No endpoints yet.

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] accounts app created + registered
- [ ] Custom User (phone = USERNAME_FIELD), manager with create_user/create_superuser
- [ ] Role + Language enums match enums.md
- [ ] AUTH_USER_MODEL set in base settings
- [ ] Django admin registration (masked phone)
- [ ] Initial migration (reversible, first domain migration)
- [ ] factory-boy UserFactory
- [ ] Tests: create user/superuser, phone uniqueness, defaults
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create_user → user with phone, no password required
- test_create_superuser → is_staff + is_superuser
- test_phone_unique → duplicate phone raises
- test_defaults → language defaults bn
### Manual QA
1. `make superuser` creates an admin by phone.
2. Django admin lists users with masked phone.

## 13. Acceptance criteria
- [ ] Custom User with phone identity works; AUTH_USER_MODEL set.
- [ ] Migration applies cleanly on a fresh DB.
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] AUTH_USER_MODEL set before any user-referencing migration
- [ ] Enums match enums.md
- [ ] Phone stored E.164
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This is the one irreversible-if-done-late decision — confirm no other migrations exist yet (only EPIC-00 core's AuditEntry/SystemConfig, which don't FK to User). If core models FK to settings.AUTH_USER_MODEL, they'll pick this up fine since it's set now.
- `last_login_at` updated by the auth flow later (T-006).
- Keep password fields present (AbstractBaseUser requires) but unused; OTP is the auth path.
