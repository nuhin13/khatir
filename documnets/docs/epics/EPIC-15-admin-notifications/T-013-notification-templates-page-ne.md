---
id: T-013
epic: EPIC-15
title: Notification templates page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-008]
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

# T-013 · Notification templates page (Next.js)

## 1. Feature goal
List of system templates (key, trigger, channels, active). Editable body/title (bilingual); variable reference shown. Cannot change trigger_event. Super+ops.

## 2. Business logic
List of system templates (key, trigger, channels, active). Editable body/title (bilingual); variable reference shown. Cannot change trigger_event. Super+ops.

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
- `key`/`trigger_event` are surfaced read-only and the editor never patches them
  (the T-008 serializer drops them on update). The spec §4.5.3 "enabled/disabled"
  toggle maps to the model's `active` flag. No create UI: the system templates
  are migration-seeded (T-008), so the page edits the seeded set only.
### Files touched (actual)
- `apps/admin/src/lib/api/notifications.ts` (template schema + fetch/update layer)
- `apps/admin/src/components/admin/notification_templates.tsx` (list + editor island)
- `apps/admin/src/app/(dashboard)/notifications/templates/page.tsx` (server guard page)
- `apps/admin/src/app/(dashboard)/_nav.ts` (Notification templates nav item)
- `apps/admin/src/test/notification-templates.test.tsx` (new RTL tests)
- `apps/admin/src/test/sidebar.test.tsx` (added to live-pages set)
## 15. Notes
List of system templates (key, trigger, channels, active). Editable body/title (bilingual); variable reference shown. Cannot change trigger_event. Super+ops.
