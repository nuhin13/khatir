---
id: T-002
epic: EPIC-17
title: EC verification provider abstraction
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-14.T-003]
blocks: [T-004]
external_services: [ec_verification]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · EC verification provider abstraction

## 1. Feature goal
A swappable provider interface that submits NID+name+DOB to the EC verification vendor and returns a normalized Matched/Not Matched (never raw data).

## 2. Business logic
VerificationProvider ABC: verify(nid, name, dob) -> VerificationResult (matched/not_matched/error) + opaque provider_ref. Concrete impl calls the approved EC vendor (credentials from config, DPA reference required). Mirrors EPIC-14 provider pattern. Raw vendor response discarded after extracting the boolean.

## 3. What this task DOES
- VerificationProvider ABC + one concrete impl; normalized result DTO; tests (mocked vendor).

## 5. Files & changes
### Add
- verification/providers/{base,ec_provider}.py, dto.py; tests/test_provider.py

## 6–10.
External: EC vendor API (mockable). No DB. No flags here.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] VerificationProvider ABC (verify → result + provider_ref)
- [ ] EC concrete impl (creds from config, DPA ref)
- [ ] discards raw vendor payload (returns boolean only)
- [ ] tests: matched, not_matched, error, mocked vendor
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_matched, test_not_matched, test_vendor_error
## 13. Acceptance criteria
- [ ] Swappable EC provider; boolean-only result; tests + lint pass.
## 14. Self-review
- [ ] Raw payload never returned/stored; DPA ref required
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Could route through the AI gateway (EPIC-14) or be a direct Django-side provider — document the choice. Either way, normalize to boolean.
