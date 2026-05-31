---
id: T-009
epic: EPIC-10
title: NID verification tier gate
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-003, EPIC-04.T-005]
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
- [ ] check_can_verify(user) → raises TierFeatureGated when not included
- [ ] wired into OCR + voice endpoints
- [ ] mobile: feature_requires_upgrade → upgrade prompt (T-008)
- [ ] manual add-tenant unaffected
- [ ] Tests: free tier blocked, bundle_10+ ok
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_ocr_blocked_free, test_ocr_ok_bundle10
### Manual QA
1. Free-tier landlord hits OCR → upgrade prompt. Bundle_10 → OCR works.

## 13. Acceptance criteria
- [ ] OCR/voice gated by tier; free-tier sees upgrade prompt; manual unaffected; tests + lint pass.
## 14. Self-review
- [ ] Error code feature_requires_upgrade; manual path unblocked
### Deviations from spec
### Files touched (actual)
## 15. Notes
- The real NID verification against EC (EPIC-17) also uses this gate.
