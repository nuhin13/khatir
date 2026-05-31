---
id: T-005
epic: EPIC-02
title: Role chooser screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004]
blocks: [T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Role chooser screen

## 1. Feature goal
Build the screen where a newly-verified user declares their role (Landlord / Building Manager / Tenant), persists it, and is routed into the matching shell.

## 2. Business logic
- Three role cards (landlord marked "most common ⭐"). Each shows Bangla + English name, a one-line description, and perk chips.
- Selecting a card → PATCH role via profile (T-003 `setRole`) → route to that role's shell home.
- Reachable again later via More → switch role.
- All copy from the design's `ROLE_CARDS`.

## 3. What this task DOES
- `features/role/presentation/screens/role_chooser_screen.dart` matching the `roleChooser` design.
- Role card widget (icon, bn/en, description, perks, "most common" badge).
- On tap → `setRole` (T-003) → `context.go` to the role's shell.
- Loading state while persisting; error handling.
- Route `/role`.
- Widget test: renders 3 cards; tapping landlord persists role + routes.

## 4. What this task does NOT do
- No redirect logic that *sends* users here (T-008 wires that).

## 5. Files & changes
### Add
- `lib/features/role/presentation/screens/role_chooser_screen.dart`
- `lib/features/role/presentation/widgets/role_card.dart`
- ARB keys
- `test/role_chooser_test.dart`
### Update
- `lib/core/router/app_router.dart` — `/role`
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
Consumes PATCH /profile (role) via T-003.

## 8. UI changes
- **Design source:** screen `roleChooser` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-onboard.js` → `reg('roleChooser')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/role`
- Translate the 3 role cards + "most common" badge + perks; values from `packages/design-tokens`
- States: data, loading (persisting selection), error
- Navigation: select → role shell home (`/landlord/home` | `/manager/home` | `/tenant/home`)
- i18n keys: `role_title`, `role_subtitle`, `role_landlord_*`, `role_manager_*`, `role_tenant_*`, `role_most_common`, `role_change_later` (bn + en) — lift copy from `ROLE_CARDS`

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] role_chooser_screen matches `roleChooser` design (3 cards, badge, perks)
- [ ] role_card widget (icon, bn/en, desc, perks, most-common)
- [ ] tap → setRole → route to role shell
- [ ] loading + error states
- [ ] route /role
- [ ] ARB copy from ROLE_CARDS (bn + en)
- [ ] Widget test: 3 cards; landlord tap persists + routes
- [ ] analyze + test pass; no inline strings/colors

## 12. Test plan
### Automated
- role_chooser_test → renders 3 cards; tap landlord calls setRole(landlord) + navigates to /landlord/home
### Manual QA
1. New user post-OTP with no role → chooser; pick Manager → manager shell; relaunch → straight to manager shell.

## 13. Acceptance criteria
- [ ] Three role cards per design with correct copy + badge + perks.
- [ ] Selection persists role and routes to the right shell.
- [ ] **Screen `roleChooser` built** (ledger row checked).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design composition; tokens via theme
- [ ] Copy from ROLE_CARDS verbatim
- [ ] Persists before routing
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- ROLE_CARDS (from design): landlord 🏠 (most common; perks: DMP ফর্ম, ভাড়া আদায়, খরচের হিসাব), manager 🏢 (perks: মাল্টি-ওনার, টিম এক্সেস, একীভূত রিপোর্ট), tenant 👤 (perks: ভাড়া পরিশোধ, রসিদ, মেরামত).
- Caretaker is NOT a self-select option here (assigned later, P2).
