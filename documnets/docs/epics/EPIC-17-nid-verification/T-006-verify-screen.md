---
id: T-006
epic: EPIC-17
title: Flutter verify screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-04.T-014, T-004]
blocks: [T-007]
external_services: []
feature_flags: [nid_verification_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Flutter verify screen

## 1. Feature goal
The verify screen: explain verification, capture consent, run it, and show the Matched / Not Matched result clearly.

## 2. Business logic
Per `verify` design. Consent checkbox (landlord attests tenant permission) → "Verify" → loading → result badge (Matched green / Not Matched amber / Error). Free-tier → upgrade prompt (reuse EPIC-10 T-008). Flag-off → feature unavailable message. Neutral "EC verification" wording (never Porichoy).

## 3. What this task DOES
- verify_screen matching `verify`; consent + run + result states; tier/flag handling. Widget test.

## 5. Files & changes
### Add
- features/verification/presentation/screens/verify_screen.dart; ARB; test
### Update
- router /tenants/:id/verify; tenant detail "Verify" CTA

## 6–10.
No DB; consumes verify endpoint; mobile 🟢; EC via backend; flag nid_verification_enabled.

## 8. UI changes
- **Design source:** screen `verify` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('verify')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/:id/verify`
- Translate consent + verify CTA + result badge; values from packages/design-tokens
- States: data (consent) / loading / matched / not_matched / error / tier-gated / flag-off
- i18n keys: `verify_title`, `verify_consent`, `verify_run`, `verify_matched`, `verify_not_matched`, `verify_error` (bn + en) — neutral EC wording

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] verify_screen matches design
- [ ] consent checkbox required before verify
- [ ] result badge (matched/not_matched/error)
- [ ] free-tier → upgrade prompt; flag-off → unavailable
- [ ] neutral "EC verification" wording (no Porichoy)
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- verify_screen_test → consent gates verify; result badge renders
### Manual QA
1. Verify a tenant → consent → Matched badge.

## 13. Acceptance criteria
- [ ] Verify screen matches design; consent enforced; result clear; tier/flag handled.
- [ ] **Screen `verify` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] No Porichoy; consent required; tokens
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Result wording: "NID Matched with EC records" / "Not Matched" — never expose any EC field values.
