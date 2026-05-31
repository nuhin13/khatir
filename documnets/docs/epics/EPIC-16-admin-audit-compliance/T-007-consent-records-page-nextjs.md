---
id: T-007
epic: EPIC-16
title: Consent records page (Next.js)
layer: admin
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-003]
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

# T-007 · Consent records page (Next.js)

## 1. Feature goal
Simple table: user, consent_type, granted_at, revoked_at, expires_at. Filter by type/user. Read-only. Compliance+super.

## 2. Business logic
Simple table: user, consent_type, granted_at, revoked_at, expires_at. Filter by type/user. Read-only. Compliance+super.

## 3. What this task DOES
See feature goal. Next.js admin UI.

## 5. Files & changes
### Add/Update
- app/(dashboard)/compliance/... ; test.
### Update
- sidebar "Compliance" → /compliance routes.

## 6–10.
No DB; consumes compliance endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Compliance + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Compliance+super route guard; Tailwind tokens

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] Core UI per description
- [ ] Compliance+super route guard
- [ ] TanStack Query; states
- [ ] Test
- [ ] tsc pass

## 12. Test plan
### Automated
- render test
## 13. Acceptance criteria
- [ ] UI works; compliance+super gate; tests pass.
## 14. Self-review
- [ ] Tailwind tokens; role gate; states
### Deviations from spec
### Files touched (actual)
## 15. Notes
Simple table: user, consent_type, granted_at, revoked_at, expires_at. Filter by type/user. Read-only. Compliance+super.
