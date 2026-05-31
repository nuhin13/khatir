---
id: T-004
epic: EPIC-17
title: Verify endpoint (consent → check → Matched/Not Matched)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, T-002, T-003, EPIC-10.T-009]
blocks: [T-006, T-008, T-010]
external_services: [ec_verification]
feature_flags: [nid_verification_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · Verify endpoint (consent → check → Matched/Not Matched)

## 1. Feature goal
The orchestrating endpoint: tier gate → consent → provider check → store result → return Matched/Not Matched.

## 2. Business logic
POST /tenants/{id}/verify: (1) tier gate (EPIC-10 T-009 — verification tiers only); (2) flag check (nid_verification_enabled); (3) capture consent (T-003); (4) call provider (T-002) with decrypted NID+name+DOB; (5) write VerificationLog (T-001) + update tenant status; (6) return {result, date}. Owner-scoped. Audited. Raw NID via audited decrypt only.

## 3. What this task DOES
- verify endpoint orchestrating the full flow; tier+flag+consent gates; audit; tests.

## 5. Files & changes
### Add
- verification/views.py, services.py, urls.py; tests/test_verify_api.py
### Update
- config/urls.py

## 6. Database changes
Writes VerificationLog + ConsentRecord + Tenant status.
## 7. API changes
| POST | /api/v1/tenants/{id}/verify | owner + verification tier | 200 |
| GET | /api/v1/tenants/{id}/verification | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
EC vendor (via T-002).
## 10. Feature flags
- nid_verification_enabled (kill-switchable)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tier gate (verification tiers; free → feature_requires_upgrade)
- [ ] flag gate (nid_verification_enabled → 403 if off)
- [ ] consent capture (T-003)
- [ ] provider call with audited NID decrypt
- [ ] write VerificationLog + status; audit
- [ ] GET last verification
- [ ] Tests: matched, not_matched, free-tier blocked, flag-off blocked, no-consent blocked
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_verify_matched, test_free_tier_blocked, test_flag_off, test_requires_consent
### Manual QA
1. Verify a tenant on bundle_10 → Matched/Not Matched.

## 13. Acceptance criteria
- [ ] Full verify flow with all gates; boolean result; audited; tests + lint pass.
## 14. Self-review
- [ ] All gates enforced; raw NID audited; no raw EC data returned
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Order matters: tier → flag → consent → check. Fail fast on each gate with a clear error code.
