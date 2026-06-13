---
id: T-009
epic: EPIC-10
title: NID verification tier gate
layer: cross-cutting
size: S
status: done
preferred_agent: codex
depends_on: [T-003, EPIC-04.T-005]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · NID verification tier gate

## 1. Feature goal
Block the NID OCR/verification endpoints for free-tier landlords, returning a tier-gated error that routes to the upgrade prompt.

## 2. Business logic
EPIC-04 T-005 (OCR) + T-006 (voice) check: if subscription.tier.includes_verification == false → raise TierFeatureGated (code `feature_requires_upgrade`). Free-tier users can still add tenants via manual entry (no OCR/verification needed).

## 3. What this task DOES
- check_can_verify(user) helper; wire into OCR + voice endpoints; tests; mobile error handling → upgrade prompt.

## 5. Files & changes
### Update
- billing/services.py (check_can_verify)
- EPIC-04 tenants/views.py (OCR + voice)
- Mobile: add-tenant OCR/voice error → upgrade prompt (reuse T-008)
### Add
- billing/tests/test_tier_gate.py

## 6–10.
No DB change; backend + mobile; no external; no flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] check_can_verify(user) → raises TierFeatureGated when not included
- [x] wired into OCR + voice endpoints
- [ ] mobile: feature_requires_upgrade → upgrade prompt (T-008) — deferred (see deviations)
- [x] manual add-tenant unaffected
- [x] Tests: free tier blocked, bundle_10+ ok
- [x] ruff clean (mypy: pre-existing factory-boy stub noise only)

## 12. Test plan
### Automated
- test_ocr_blocked_free, test_ocr_ok_bundle10
### Manual QA
1. Free-tier landlord hits OCR → upgrade prompt. Bundle_10 → OCR works.

## 13. Acceptance criteria
- [x] OCR/voice gated by tier (backend); free-tier returns the `feature_requires_upgrade`
  upgrade envelope; manual tenant create unaffected; tests + ruff pass.
## 14. Self-review
- [x] Error code feature_requires_upgrade; manual path unblocked
### Deviations from spec
- Added `ErrorCode.FEATURE_REQUIRES_UPGRADE` to `core/enums.py` and a
  `TierFeatureGated` AppError (402) in `core/exceptions.py` — the spec named the
  code but the canonical enum had only `tier_limit_exceeded`. Chose 402
  (upgrade-required), consistent with T-003's `TierLimitExceeded`.
- `check_can_verify` allows verification only for an **active** subscription whose
  tier has `includes_verification == True`; free tier (no subscription) and paid
  tiers without the flag are blocked. Read is not locked (no write/race window,
  unlike the tenant-count check).
- **Mobile portion deferred.** §5 says "reuse T-008" for the upgrade prompt and
  wire it into the add-tenant OCR/voice flow, but at this branch HEAD T-008
  (`upgrade_prompt.dart`) is still `status: todo` and the EPIC-04 mobile
  add-tenant OCR/voice screens do not yet exist (`apps/mobile/lib/features` has
  no tenant feature). The backend gate — the core of T-009 and the target of the
  automated test plan (`test_ocr_blocked_free`, `test_ocr_ok_bundle10`) — is
  complete; the mobile intercept should be picked up once T-008 + the EPIC-04
  add-tenant screens land. The new `feature_requires_upgrade` code reuses the same
  intercept pattern T-008 builds for `tier_limit_exceeded`.
- Updated the existing OCR/voice endpoint tests to put their landlord/manager on a
  verification-enabled tier (the new gate would otherwise 402 them); the free-tier
  block is asserted in the new `test_tier_gate.py`.
### Files touched (actual)
- apps/api/khatir/core/enums.py (FEATURE_REQUIRES_UPGRADE)
- apps/api/khatir/core/exceptions.py (TierFeatureGated → 402)
- apps/api/khatir/billing/services.py (check_can_verify)
- apps/api/khatir/tenants/views.py (OCR + voice call check_can_verify)
- apps/api/khatir/billing/tests/test_tier_gate.py (new)
- apps/api/khatir/tenants/tests/test_ocr_endpoint.py (grant verification tier)
- apps/api/khatir/tenants/tests/test_voice_endpoint.py (grant verification tier)
## 15. Notes
- The real NID verification against EC (EPIC-17) also uses this gate.
