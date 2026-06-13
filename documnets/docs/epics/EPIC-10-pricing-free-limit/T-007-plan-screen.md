---
id: T-007
epic: EPIC-10
title: Flutter plan screen
layer: mobile
size: M
status: done
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
- [x] plan_screen matches design
- [x] current tier highlighted; usage bar
- [x] all tiers as upgrade cards
- [x] subscribe action (wires to T-004)
- [x] More → Plan linked
- [x] states; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- plan_screen_test → renders tiers; current highlighted; subscribe fires
### Manual QA
1. Open Plan → see 6 tiers; current = free; usage shows 1/2; upgrade to bundle_10.

## 13. Acceptance criteria
- [x] Plan screen matches design; tiers from DB; subscribe works.
- [x] **Screen `plan` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tiers from config not hardcoded; tokens
### Deviations from spec
- The proto hardcodes 4 illustrative tiers; the screen renders whatever active
  tiers `/config/public` returns (T-005), so prices/labels/bands are never
  hardcoded. The "best value" ring is applied to the unlimited (top) tier to
  mirror the proto's single ringed card.
- Subscribe is stubbed server-side (T-004): success shows a "we'll confirm"
  snackbar and re-reads `/config/public` to refresh usage; no real MFS flow.
### Files touched (actual)
- Add: `apps/mobile/lib/features/billing/data/models/plan_models.dart`
- Add: `apps/mobile/lib/features/billing/data/billing_repository.dart`
- Add: `apps/mobile/lib/features/billing/data/billing_providers.dart`
- Add: `apps/mobile/lib/features/billing/presentation/screens/plan_screen.dart`
- Add: `apps/mobile/test/plan_screen_test.dart`
- Update: `apps/mobile/lib/core/network/api_endpoints.dart` (billingSubscribe)
- Update: `apps/mobile/lib/core/router/app_router.dart` (/settings/plan route)
- Update: `apps/mobile/lib/features/profile/presentation/screens/more_screen.dart` (Plan row → /settings/plan)
- Update: `apps/mobile/lib/l10n/app_bn.arb`, `apps/mobile/lib/l10n/app_en.arb` (plan_* keys)

## 15. Notes for the implementing agent
- Tier data comes from /config/public (not a separate fetch). Payment is stubbed — show a confirmation and a "we'll confirm" message.
