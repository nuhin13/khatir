---
id: T-007
epic: EPIC-02
title: More menu screen (profile, language, role switch, logout)
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-004, T-003]
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

# T-007 · More menu screen (profile, language, role switch, logout)

## 1. Feature goal
Build the More menu: a profile header, a list of secondary actions (plan/billing, AI lease, warnings, language, switch role, about), and logout — the settings hub for each role shell.

## 2. Business logic
From the `more` design: profile row (avatar, name, phone, tier chip), then a card list of rows each routing somewhere, then a logout button. Language row toggles bn/en in place. Switch-role routes to `roleChooser`. Some rows (AI lease, warnings, plan) point at screens built in later epics — route to them (they may be placeholders until then).

## 3. What this task DOES
- `features/profile/presentation/screens/more_screen.dart` matching `more` design.
- Profile header (avatar, name, masked phone, plan chip from subscription — placeholder text until EPIC-10).
- Action rows: Profile, Plan & billing (`/settings/plan`), AI lease (`/lease/generate`), Warnings (`/warning`), Language (in-place bn/en toggle via T-003 `setLanguage`), Switch role (`/role`), About (`/onboarding`).
- Logout button → `authController.logout()` → `/auth/phone`.
- Used by all role shells' More tab (content adapts slightly per role; tenant More is simpler).
- Widget test: renders rows; language toggle switches locale; logout clears session.

## 4. What this task does NOT do
- Does not build the destination screens (plan/lease/warning are later epics).
- No edit-profile form beyond name/language (full profile editing can be a later enhancement).

## 5. Files & changes
### Add
- `lib/features/profile/presentation/screens/more_screen.dart`
- `lib/features/profile/presentation/widgets/more_row.dart`
- ARB keys
- `test/more_screen_test.dart`
### Update
- shells' More branch → render MoreScreen
### Delete
- none

## 6. Database changes
No DB changes.

## 7. API changes
Uses /profile (T-001) + /auth/logout (EPIC-01).

## 8. UI changes
- **Design source:** screen `more` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('more')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/landlord/more` (+ `/manager/more`, `/tenant/more`)
- Translate profile header + row list + logout; values from `packages/design-tokens`
- States: data, loading (profile fetch), error
- Navigation: rows route as listed; language toggles in place; logout → `/auth/phone`
- i18n keys: `more_profile`, `more_plan`, `more_lease`, `more_warnings`, `more_language`, `more_switch_role`, `more_about`, `more_logout` (bn + en) — lift copy from the `more` screen

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] more_screen matches `more` design (header + rows + logout)
- [ ] profile header (avatar, name, masked phone, plan chip placeholder)
- [ ] rows route correctly (later-epic targets as placeholders)
- [ ] language row toggles bn/en in place (setLanguage)
- [ ] switch role → /role; about → /onboarding
- [ ] logout → authController.logout → /auth/phone
- [ ] used by all shells' More tab (tenant simpler)
- [ ] ARB bn + en
- [ ] Widget test: rows render, language toggle, logout
- [ ] analyze + test pass

## 12. Test plan
### Automated
- more_screen_test → rows render; tap language toggles locale; tap logout clears session + routes
### Manual QA
1. Open More → toggle language → UI switches; switch role → chooser; logout → phone.

## 13. Acceptance criteria
- [ ] More menu matches design; all rows route; language + logout work.
- [ ] **Screen `more` built** (ledger row checked).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens via theme
- [ ] Later-epic targets clearly routed (placeholders ok)
- [ ] Logout fully clears session
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- `more` rows (from design): Profile, Plan & billing, AI lease, Warnings, Language (bn/EN), Switch role, About Khatir, + Logout. Tenant's More omits landlord-only rows (lease/warnings) — adapt per role, follow `tenHome`/design.
- Plan chip ("Free 1/2") is real in EPIC-10; show a placeholder now.
