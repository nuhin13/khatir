---
id: T-002
epic: EPIC-17
title: EC verification provider abstraction
layer: backend
size: M
status: done
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
- [x] VerificationProvider ABC (verify → result + provider_ref)
- [x] EC concrete impl (creds from config, DPA ref)
- [x] discards raw vendor payload (returns boolean only)
- [x] tests: matched, not_matched, error, mocked vendor
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_matched, test_not_matched, test_vendor_error
## 13. Acceptance criteria
- [x] Swappable EC provider; boolean-only result; tests + lint pass.
## 14. Self-review
- [x] Raw payload never returned/stored; DPA ref required
### Deviations from spec
- Files live under the Django app `apps/api/khatir/verification/providers/`
  (`base.py`, `ec_provider.py`, `dto.py`, `__init__.py`) + `tests/test_provider.py`,
  matching the spec's relative paths inside the epic's own app.
- DTO is named `VerificationOutcome` (the model-level `VerificationResult` enum
  from T-001 is reused as the outcome field, sharing wire values 1:1).
- HTTP via `requests` (already a dep; `httpx` is gateway-only). Vendor session
  is injectable for tests; transport/HTTP/JSON failures normalize to an `error`
  outcome rather than raising.
### Files touched (actual)
- apps/api/khatir/verification/providers/{__init__,base,ec_provider,dto}.py (new)
- apps/api/khatir/verification/tests/test_provider.py (new)
- apps/api/config/settings/base.py (EC_VERIFICATION_* settings)
## 15. Notes
- Chose a **direct Django-side provider** (not the AI gateway): identity
  verification is a synchronous Django concern with its own DPA-gated vendor,
  and routing PII through the AI gateway would widen the data-processing
  surface. The interface mirrors the EPIC-14 provider pattern so it stays
  swappable. Result is always normalized to a boolean-only outcome.
