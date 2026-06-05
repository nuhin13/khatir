---
id: T-007
epic: EPIC-16
title: Consent records page (Next.js)
layer: admin
size: S
status: done
preferred_agent: claude-code
depends_on: [T-003]
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
- [x] Core UI per description
- [x] Compliance+super route guard
- [x] TanStack Query; states
- [x] Test
- [x] tsc pass

## 12. Test plan
### Automated
- render test
## 13. Acceptance criteria
- [x] UI works; compliance+super gate; tests pass.
## 14. Self-review
- [x] Tailwind tokens; role gate; states
### Deviations from spec
- The T-003 consent endpoint uses page-number pagination (not cursor), so the
  table paginates via the `?page=N` next/previous links rather than a cursor.
- Consent records are append-only and read-only, so there is no
  create/edit/delete affordance — the page is a filterable read-only table only.
### Files touched (actual)
- apps/admin/src/lib/api/consent.ts (new)
- apps/admin/src/components/admin/consent_table.tsx (new)
- apps/admin/src/app/(dashboard)/compliance/consent/page.tsx (new)
- apps/admin/src/app/(dashboard)/compliance/consent/consent_client.tsx (new)
- apps/admin/src/app/(dashboard)/_nav.ts (added Consent records nav item)
- apps/admin/src/test/consent.test.tsx (new)
- apps/admin/src/test/sidebar.test.tsx (added Consent records to live-pages)
## 15. Notes
Simple table: user, consent_type, granted_at, revoked_at, expires_at. Filter by type/user. Read-only. Compliance+super.
