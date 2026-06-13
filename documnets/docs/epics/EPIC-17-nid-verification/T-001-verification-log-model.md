---
id: T-001
epic: EPIC-17
title: VerificationLog model + Tenant status update
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-04.T-001, EPIC-16.T-001]
blocks: [T-004, T-009]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · VerificationLog model + Tenant status update

## 1. Feature goal
Persist verification attempts as boolean-only results — never raw EC data — and update the tenant's verification status.

## 2. Business logic
VerificationLog(tenant FK, requested_by FK User, result enum matched/not_matched/error, provider_ref opaque string, consent_record FK, created_at). Append-only. On matched → Tenant.verification_status=verified; not_matched → failed. NO raw EC fields anywhere.

## 3. What this task DOES
- VerificationLog model + VerificationResult enum + Tenant status transition helper; migration; admin (result only); tests asserting no raw-data column.

## 5. Files & changes
### Add
- khatir/verification/{__init__,apps,models,enums}.py, migration, tests/factories
### Update
- settings register; Tenant status helper

## 6. Database changes
Creates verification_verificationlog. Reversible.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] VerificationLog (result enum, provider_ref opaque, consent FK)
- [ ] append-only manager
- [ ] Tenant.verification_status transition
- [ ] NO raw EC field columns
- [ ] migration reversible; admin (result only)
- [ ] tests: create, no-raw-data assertion
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_log_create, test_no_raw_data_columns, test_status_transition
## 13. Acceptance criteria
- [ ] Boolean-only verification log; status transitions; tests + lint pass.
## 14. Self-review
- [ ] Only matched/not_matched/error stored; no EC payload
### Deviations from spec
### Files touched (actual)
## 15. Notes
- provider_ref is an opaque vendor transaction id for audit/dispute — NOT the EC data itself.
