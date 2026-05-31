---
id: T-010
epic: EPIC-15
title: Notification composer page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-007, EPIC-11.T-008]
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
- [ ] Core UI per description
- [ ] Super+ops route guard
- [ ] TanStack Query; loading/error/data states
- [ ] Test (render + interaction)
- [ ] eslint + tsc pass

## 12. Test plan
### Automated
- Core render tests
## 13. Acceptance criteria
- [ ] UI works per goal; states; super+ops gate; tests pass.
## 14. Self-review
- [ ] Tailwind tokens; super+ops; states complete
### Deviations from spec
### Files touched (actual)
## 15. Notes
Compose form: audience (all/role/segment/IDs), channels (inapp/WhatsApp/SMS/email), bilingual title+body with variable chips, schedule (now/scheduled/recurring), reach+cost preview. Submit creates + schedules. Super+ops.
