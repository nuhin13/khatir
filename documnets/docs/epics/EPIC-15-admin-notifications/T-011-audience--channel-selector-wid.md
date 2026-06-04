---
id: T-011
epic: EPIC-15
title: Audience + channel selector widgets
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-010]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-011 · Audience + channel selector widgets

## 1. Feature goal
Reusable AudienceSelector (all/role/segment/specific users search) and ChannelSelector (checkbox per channel) components — used by composer (T-010) and potentially by other admin flows.

## 2. Business logic
Reusable AudienceSelector (all/role/segment/specific users search) and ChannelSelector (checkbox per channel) components — used by composer (T-010) and potentially by other admin flows.

## 3. What this task DOES
See feature goal. Next.js admin UI component per the description.

## 5. Files & changes
### Add
- app/(dashboard)/notifications/... ; components/admin/... ; test.
### Update
- sidebar "Notifications" → /notifications (if not linked).

## 6–10.
No DB; consumes notifications endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Notifications + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Tailwind-themed; Notun Din tokens

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core UI per description
- [x] Super+ops route guard (host page /notifications gates super+ops; selectors are presentational)
- [x] TanStack Query; loading/error/data states (data states owned by the composer host; selectors are controlled)
- [x] Test (render + interaction)
- [x] eslint + tsc pass

## 12. Test plan
### Automated
- Core render tests
## 13. Acceptance criteria
- [x] UI works per goal; states; super+ops gate; tests pass.
## 14. Self-review
- [x] Tailwind tokens; super+ops; states complete
### Deviations from spec
- The selectors are presentational, controlled widgets (caller owns state); the
  super+ops route guard and TanStack Query data/loading/error states live in the
  host page/composer (T-010), not the widgets themselves. The composer (T-010)
  was refactored to consume `AudienceSelector` + `ChannelSelector`, removing the
  previously-inline duplicated sections — behaviour and rendered markup are
  unchanged so the T-010 tests still pass.
- "Specific users search" is realised as the comma/space-separated user-ID input
  carried over from T-010 (no live user-search endpoint is exposed by T-007);
  the input acts as the search/entry field.
### Files touched (actual)
- apps/admin/src/components/admin/audience_selector.tsx (add)
- apps/admin/src/components/admin/channel_selector.tsx (add)
- apps/admin/src/components/admin/notification_composer.tsx (refactor to consume widgets)
- apps/admin/src/test/audience-channel-selectors.test.tsx (add)
## 15. Notes
Reusable AudienceSelector (all/role/segment/specific users search) and ChannelSelector (checkbox per channel) components — used by composer (T-010) and potentially by other admin flows.
