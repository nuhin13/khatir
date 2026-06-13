---
id: T-001
epic: EPIC-16
title: ConsentRecord + DataRequest models
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-003, T-004]
external_services: []
feature_flags: []
started_at: 2026-06-04completed_at: 2026-06-04executed_by: claudereviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · ConsentRecord + DataRequest models

## 1. Feature goal
Create ConsentRecord and DataRequest models for PDPA compliance.

## 2. Business logic
ConsentRecord(user FK, consent_type varchar, granted_at, revoked_at nullable, expires_at nullable). DataRequest(user FK, request_type export/delete, status pending/processing/completed/rejected, sla_due, completed_at, handled_by FK AdminUser). Append-only consent records (no delete).

## 3. What this task DOES
- compliance app; both models; enums; migration; admin; tests.

## 5. Files & changes
### Add
- khatir/compliance/{__init__,apps,models,enums}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
2 tables. Reversible.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] ConsentRecord (consent_type, granted/revoked/expires)
- [ ] DataRequest (type, status enum, sla_due, handled_by)
- [ ] ConsentRecord append-only manager
- [ ] migrations reversible
- [ ] tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_consent_create, test_data_request_create
## 13. Acceptance criteria
- [ ] Models; migration clean; tests + lint pass.
## 14. Self-review
- [ ] ConsentRecord append-only
### Deviations from spec
### Files touched (actual)
## 15. Notes
- ConsentRecord should never be deleted (regulatory requirement). Use append-only manager pattern like KillSwitchEvent.
