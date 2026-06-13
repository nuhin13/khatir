---
id: T-006
epic: EPIC-16
title: Enhanced audit log page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, EPIC-11.T-008]
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

# T-006 · Enhanced audit log page (Next.js)

## 1. Feature goal
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.

## 2. Business logic
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.

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
- Audit log moved under the Compliance module at `/compliance/audit` (Admin
  Portal spec §4.5.1 makes the audit log the module's first tab). The legacy
  `/audit` route and the `/compliance` module root both redirect there. The
  sidebar "Compliance" item is promoted from coming-soon to a live route; the
  existing "Audit log" item now points at `/compliance/audit`.
### Files touched (actual)
- `app/(dashboard)/compliance/audit/page.tsx` — server component, compliance+super role guard + access-denied panel.
- `app/(dashboard)/compliance/audit/audit_client.tsx` — client viewer: TanStack Query, filters, cursor pagination, CSV-export button.
- `app/(dashboard)/compliance/page.tsx` — redirect to `/compliance/audit`.
- `app/(dashboard)/audit/page.tsx` — legacy route redirect to `/compliance/audit`.
- `app/(dashboard)/_nav.ts` — Audit log → `/compliance/audit`; Compliance promoted to live route.
- `lib/api/audit.ts` — `auditCsvUrl(filters)` builds the absolute `?format=csv` export URL (T-002 stream).
- `test/audit.test.tsx` — render test now targets `AuditLogClient`; adds CSV-export-link + filter-threading tests.
- `test/sidebar.test.tsx` — Compliance added to the live-pages set.
## 15. Notes
Replaces EPIC-11 T-011 with the enhanced version: full filters (actor/action/entity/date), CSV export button, expanded before/after diff. Compliance+super.
