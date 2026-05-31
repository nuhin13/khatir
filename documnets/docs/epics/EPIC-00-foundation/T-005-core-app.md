---
id: T-005
epic: EPIC-00
title: Django core app (base models, envelope, exceptions, config accessor)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004]
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

# T-005 · Django core app (base models, envelope, exceptions, config accessor)

## 1. Feature goal
Create the shared `khatir/core` app holding the base classes and cross-cutting utilities every domain app reuses: timestamped/soft-delete models, the standard API response/error envelope, the exception handler, pagination, the audit writer stub, the encryption helper, the cross-app enums, and the cached `SystemConfig` accessor.

## 2. Business logic
Implements the cross-cutting rules from `04_coding_conventions.md` (error envelope, pagination, audit, multi-tenancy base) and `03_env_and_config.md` (SystemConfig Layer-3 accessor). These are the primitives, not domain logic.

## 3. What this task DOES
- `core/models.py`: `TimeStampedModel`, `SoftDeleteModel` (+ manager that excludes deleted).
- `core/exceptions.py`: custom exceptions + DRF exception handler producing the standard error envelope (`{error:{code,message,details}}`), wired into DRF settings.
- `core/responses.py`: helpers for consistent success/paginated responses.
- `core/pagination.py`: standard page-number + cursor pagination classes.
- `core/enums.py`: cross-app enums from `enums.md` (Role, Language, Channel, ErrorCode, etc.).
- `core/encryption.py`: Fernet-based field encrypt/decrypt + a masking helper, keyed by `FIELD_ENCRYPTION_KEY`.
- `core/audit.py`: `audit(actor, action, target, before, after)` writing an `AuditEntry` row (model lives here in core).
- `core/config.py`: `get_config(key)` cached accessor over a `SystemConfig` model (model in core), 60s TTL, invalidated on write.
- `core/permissions.py`: base permission classes + a `ForUserQuerySetMixin`/manager pattern doc-comment for domain apps to follow.
- Migrations for `AuditEntry` + `SystemConfig`.
- Tests for each utility.

## 4. What this task does NOT do
- No domain models (buildings/tenants/etc.).
- No feature flags app (EPIC-13) — but `SystemConfig` is created here.

## 5. Files & changes
### Add
- `apps/api/khatir/core/__init__.py`, `apps.py`, `models.py`, `enums.py`, `exceptions.py`, `responses.py`, `pagination.py`, `encryption.py`, `audit.py`, `config.py`, `permissions.py`
- `apps/api/khatir/core/migrations/0001_initial.py`
- `apps/api/khatir/core/tests/{test_models,test_encryption,test_exceptions,test_config,test_audit}.py`
### Update
- `config/settings/base.py` — register `khatir.core`, set DRF `EXCEPTION_HANDLER` + default pagination
### Delete
- none

## 6. Database changes
- Migration adds `AuditEntry` and `SystemConfig` tables (see `06_database_schema.md` Domain 8).
- Reversible.

## 7. API changes
No new endpoints. Standardizes the error envelope on existing ones.

## 8. UI changes
No UI changes.

## 9. External services
None. Uses `FIELD_ENCRYPTION_KEY` env for encryption.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] TimeStampedModel + SoftDeleteModel (+ manager)
- [ ] Error envelope exception handler wired in DRF settings
- [ ] Success/paginated response helpers
- [ ] Page-number + cursor pagination classes
- [ ] Cross-app enums from enums.md (TextChoices)
- [ ] Fernet encryption + masking helper
- [ ] AuditEntry model + audit() writer
- [ ] SystemConfig model + cached get_config()
- [ ] Base permission classes + for_user pattern documented
- [ ] Migration (reversible)
- [ ] Tests for each utility pass

## 12. Test plan
### Automated
- test_models → timestamps set; soft-delete hides rows
- test_encryption → encrypt/decrypt round-trip; mask format
- test_exceptions → raising AppError yields the standard envelope + code
- test_config → get_config caches + invalidates on write
- test_audit → audit() writes an AuditEntry with before/after
### Manual QA
1. Trigger a validation error on /api/v1/config/public path and confirm the envelope shape.

## 13. Acceptance criteria
- [ ] All base classes importable + used by a trivial example.
- [ ] Error envelope matches `04_coding_conventions.md` §1.
- [ ] Encryption round-trips; mask hides all but last 4.
- [ ] Tests + ruff + mypy pass.

## 14. Self-review
- [ ] Enum values match enums.md exactly
- [ ] No domain logic leaked into core
- [ ] Audit + config tested
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Error `code` values must come from the `ErrorCode` enum in `enums.md`.
- `get_config` returns typed values per `SystemConfig.type` (int/money/text/bool).
- Encryption uses `cryptography` Fernet with `FIELD_ENCRYPTION_KEY`; never log decrypted values.
- Keep `core` free of imports from domain apps (core is a leaf dependency).
