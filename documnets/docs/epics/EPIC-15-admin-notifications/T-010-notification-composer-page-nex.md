---
id: T-010
epic: EPIC-15
title: Notification composer page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-007, EPIC-11.T-008]
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

# T-010 · Notification composer page (Next.js)

## 1. Feature goal
Compose form: audience (all/role/segment/IDs), channels (inapp/WhatsApp/SMS/email), bilingual title+body with variable chips, schedule (now/scheduled/recurring), reach+cost preview. Submit creates + schedules. Super+ops.

## 2. Business logic
Compose form: audience (all/role/segment/IDs), channels (inapp/WhatsApp/SMS/email), bilingual title+body with variable chips, schedule (now/scheduled/recurring), reach+cost preview. Submit creates + schedules. Super+ops.

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
- [x] Super+ops route guard
- [x] TanStack Query; loading/error/data states
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
- Reach/cost live-preview shows a server-resolved figure only on submit for
  broad audiences (all/role/segment) — provisional reach is computed client-side
  only for the `specific` audience (the count of entered IDs), since resolving an
  `all`/`role` audience requires the backend. The authoritative reach + cost come
  back from the compose response (services.py injects `reach`/`estimated_cost`).
- WhatsApp/SMS preview-bubble mock and MFA-over-Tk-5000 re-prompt (spec §4.5.1)
  are out of scope for this composer task; the per-channel cost table and reach
  summary are surfaced. The dedicated reach+cost widget is T-014 and the audience
  + channel selector widget is T-011; this task ships a self-contained composer.
### Files touched (actual)
- apps/admin/src/lib/api/notifications.ts (add)
- apps/admin/src/components/admin/notification_composer.tsx (add)
- apps/admin/src/app/(dashboard)/notifications/page.tsx (replace ComingSoon)
- apps/admin/src/app/(dashboard)/_nav.ts (Notifications → super+ops, live)
- apps/admin/src/test/notifications.test.tsx (add)
- apps/admin/src/test/sidebar.test.tsx (Notifications now a live page)
## 15. Notes
Compose form: audience (all/role/segment/IDs), channels (inapp/WhatsApp/SMS/email), bilingual title+body with variable chips, schedule (now/scheduled/recurring), reach+cost preview. Submit creates + schedules. Super+ops.
