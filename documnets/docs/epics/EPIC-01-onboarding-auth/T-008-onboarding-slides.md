---
id: T-008
epic: EPIC-01
title: Flutter onboarding slides
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-00.T-008]
blocks: [T-009]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Flutter onboarding slides

## 1. Feature goal
Build the 3-slide intro that a first-time user sees, communicating Khatir's value (welcome → the DMP/police-form wedge → the free hook), in Bangla by default, skippable, and re-viewable later.

## 2. Business logic
- Shown only on first launch (a "seen onboarding" flag persisted locally); skippable if `intro_slide_skip_allowed` (from `/config/public`) is true.
- After finishing/skipping, route to `/auth/phone`.
- Re-accessible later from the More tab (wired in EPIC-02, but the route exists now).

## 3. What this task DOES
- `features/onboarding/` with a 3-page PageView, dots indicator, Skip + Next/Get-Started buttons (KButton).
- Content per the mobile UI reference, all strings via ARB (bn + en).
- Persist "onboarding seen" in secure storage / shared prefs.
- Read `intro_slide_skip_allowed` from a config provider (calls `/config/public`).
- Route `/onboarding`; on finish → `/auth/phone`.
- Widget test: renders 3 slides, Skip routes onward.

## 4. What this task does NOT do
- No auth logic (T-009+).
- The More-tab entry point is added in EPIC-02 (route exists, link later).

## 5. Files & changes
### Add
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `lib/features/onboarding/presentation/widgets/slide.dart`, `dots_indicator.dart`
- `lib/features/onboarding/data/onboarding_prefs.dart` (seen flag)
- `lib/core/config/public_config_provider.dart` (fetch /config/public) — if not present
- ARB keys in `app_bn.arb` + `app_en.arb`
- `test/onboarding_screen_test.dart`
### Update
- `lib/core/router/app_router.dart` — add `/onboarding`
### Delete
- the EPIC-00 placeholder screen/route (superseded by real flow) — or keep until T-012 wires splash

## 6. Database changes
No DB changes.

## 7. API changes
Consumes `GET /api/v1/config/public` (already exists).

## 8. UI changes
- **Design source:** screen `intro` (3 slides) + `splash` handled in T-012 — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-onboard.js` → `reg('intro')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Screen/route: `/onboarding` (PageView of 3)
- Translate layout + composition + copy; values from `packages/design-tokens`
- States: data (static content) + a loading guard while config loads
- Navigation: finish/skip → `/auth/phone`
- i18n keys: `onboarding_slide1_title/body`, `slide2`, `slide3`, `onboarding_skip`, `onboarding_next`, `onboarding_start` (bn + en) — lift the Bangla/English copy from the `intro` screen's `INTRO[]` array

## 9. External services
None.

## 10. Feature flags
None (skip controlled by SystemConfig `intro_slide_skip_allowed`).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] 3-slide PageView + dots + Skip/Next/Start (KButton, theme tokens)
- [ ] Content from ARB (bn default + en)
- [ ] "onboarding seen" persisted
- [ ] Reads intro_slide_skip_allowed from /config/public
- [ ] Route /onboarding; finish → /auth/phone
- [ ] Loading + data states
- [ ] Widget test: 3 slides render; skip navigates
- [ ] flutter analyze + test pass; no inline strings/colors

## 12. Test plan
### Automated
- onboarding_screen_test → renders 3 pages; Skip triggers navigation
### Manual QA
1. Fresh install → slides in Bangla; toggle to en; Skip → phone screen.
2. Relaunch → onboarding not shown again.

## 13. Acceptance criteria
- [ ] 3 slides, Bangla default, skippable per config, re-route to phone.
- [ ] Seen-flag prevents re-show.
- [ ] No hardcoded strings/colors; test + analyze pass.

## 14. Self-review
- [ ] All strings via ARB; tokens via theme
- [ ] Config-driven skip
- [ ] Seen-flag persists
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Slide content (reference): 1) "খাতির — বাড়িওয়ালার ডিজিটাল খাতা" welcome; 2) the DMP/police-form-in-2-minutes wedge; 3) "প্রথম ২ ভাড়াটিয়া ফ্রি" hook. Final copy in ARB, keep it short.
- Use the Notun Din illustrations/colors; no external image fetch (bundle assets).
