---
id: T-003
epic: EPIC-17
title: Consent capture + ConsentRecord write
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-16.T-001]
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

# T-003 · Consent capture + ConsentRecord write

## 1. Feature goal
Record explicit consent (consent_type=nid_verification) before any verification runs — a PDPA requirement.

## 2. Business logic
record_verification_consent(tenant, by_user) → creates ConsentRecord (EPIC-16 model). Verification (T-004) refuses to run without a valid (non-revoked, non-expired) consent record. Consent is the landlord attesting they have the tenant's permission.

## 3. What this task DOES
- Consent write helper + has_valid_consent check; tests.

## 5. Files & changes
### Add
- verification/consent.py; tests/test_consent.py

## 6–10.
Writes ConsentRecord (EPIC-16). No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] record_verification_consent → ConsentRecord
- [x] has_valid_consent(tenant) check
- [x] tests: consent recorded, validity check
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_consent_recorded, test_valid_consent_check
## 13. Acceptance criteria
- [x] Consent captured + checkable; tests + lint pass.
## 14. Self-review
- [x] Verification can't run without consent (enforced in T-004)
### Deviations from spec
- consent_type uses the existing EPIC-16 enum value `ConsentType.PDPA_NID_VERIFICATION`
  (`pdpa_nid_verification`) rather than the bare `nid_verification` string in the
  spec note; the enum is the source of truth and has no `nid_verification` member.
- ConsentRecord (EPIC-16) has no `tenant` FK, so `has_valid_consent(tenant)` scopes
  consent to the tenant via the `VerificationLog.consent_record` reverse relation
  (`verification_logs__tenant`). T-004 records consent then links the returned
  record to the VerificationLog it writes.
### Files touched (actual)
- Add: apps/api/khatir/verification/consent.py
- Add: apps/api/khatir/verification/tests/test_consent.py
## 15. Notes
- consent_type = 'nid_verification'. Consent is per-verification (or time-bounded) — follow PDPA guidance.
