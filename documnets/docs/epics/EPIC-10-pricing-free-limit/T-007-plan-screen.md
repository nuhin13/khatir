---
id: T-007
epic: EPIC-10
title: Flutter plan screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004, T-005]
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

# T-007 · Flutter plan screen

## 1. Feature goal
The plan & billing screen: shows current tier, usage (N/limit), all tier options, and an upgrade path.

## 2. Business logic
Per `plan` design. Reads /config/public (subscription + tiers). Shows current tier highlighted; other tiers as upgrade cards with prices, limits, features. Tap → subscribe flow. Replace More → Plan placeholder.

## 3. What this task DOES
- plan_screen.dart matching `plan`; tier cards; subscribe action; states. Widget test.

## 5. Files & changes
### Add
- features/billing/presentation/screens/plan_screen.dart; data layer (models/repo/providers); ARB; test
### Update
- More screen Plan row → /settings/plan for real

## 6–10.
No DB; consumes /config/public + /billing/subscribe; surface mobile 🟢; no external; no flags.

## 8. UI changes
- **Design source:** screen `plan` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('plan')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/settings/plan`
- Translate current tier + usage bar + tier cards; values from packages/design-tokens
- States: loading / data / subscribing
- Navigation: upgrade → subscribe; back → More
- i18n keys: `plan_title`, `plan_current`, `plan_usage`, `plan_upgrade`, `plan_free`, `plan_billing_*` (bn + en) — lift copy from `plan`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] plan_screen matches design
- [ ] current tier highlighted; usage bar
- [ ] all tiers as upgrade cards
- [ ] subscribe action (wires to T-004)
- [ ] More → Plan linked
- [ ] states; ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- plan_screen_test → renders tiers; current highlighted; subscribe fires
### Manual QA
1. Open Plan → see 6 tiers; current = free; usage shows 1/2; upgrade to bundle_10.

## 13. Acceptance criteria
- [ ] Plan screen matches design; tiers from DB; subscribe works.
- [ ] **Screen `plan` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tiers from config not hardcoded; tokens
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Tier data comes from /config/public (not a separate fetch). Payment is stubbed — show a confirmation and a "we'll confirm" message.
