---
id: T-011
epic: EPIC-11
title: Audit log viewer page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002, T-008]
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

# T-011 · Audit log viewer page (Next.js)

## 1. Feature goal
A searchable, filterable admin audit log viewer — every admin action, who did it, when, before/after.

## 2. Business logic
Table with filters: admin user, action type, date range, entity type. Paginated. Before/after JSON diff expandable. Compliance role read-only. No delete.

## 3. What this task DOES
- /audit page; table with filters + pagination; diff expander; tests.

## 5. Files & changes
### Add
- app/(dashboard)/audit/page.tsx; components/admin/audit_table.tsx; backend GET /admin/api/audit-log; test

## 6–10.
DB reads; admin 🟣; no external; no flags.

## 7. API changes
| GET | /admin/api/audit-log | admin compliance+ | 200 paginated |

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Compliance/Audit
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/audit`
- Filterable table; diff expander; Notun Din Tailwind tokens

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] backend GET /audit-log (paginated, filterable)
- [x] audit_table component (filters + pagination)
- [x] before/after JSON diff expander
- [x] compliance role access
- [x] no delete/edit on entries
- [x] tests: render, filter, pagination
- [x] eslint + tsc pass

## 12. Test plan
### Automated
- audit_log_page renders; filter changes query
### Manual QA
1. Admin action → appears in audit log with diff.

## 13. Acceptance criteria
- [x] Audit log viewer; filterable; diff expander; compliance role; no delete; tests pass.
## 14. Self-review
- [x] Immutable; compliance-accessible
### Deviations from spec
- Backend `GET /admin/api/audit-log` uses the current admin JWT realm
  (`AdminJWTAuthentication` + `request.admin_user`) gated on the `audit` section
  (super + compliance), matching the newer T-012/T-003+ endpoints rather than the
  older `permissions._decode_admin_principal` style. Cursor pagination
  (`StandardCursorPagination`) per `core.pagination` guidance for append-only sets.
- Read-only by construction: no create/update/delete route; non-GET methods 405.
- Frontend nav adds an "Audit log" item at `/audit` (compliance-gated) beside the
  existing coming-soon Compliance stub; the `sidebar` "all unbuilt = comingSoon"
  test was widened to allow built pages (Dashboard + Audit log).
### Files touched (actual)
- apps/api/khatir/admin_portal/audit_serializers.py (add)
- apps/api/khatir/admin_portal/audit_views.py (add)
- apps/api/khatir/admin_portal/admin_urls.py (route)
- apps/api/khatir/admin_portal/tests/test_audit_log_view.py (add)
- apps/admin/src/lib/api/audit.ts (add)
- apps/admin/src/components/admin/audit_table.tsx (add)
- apps/admin/src/app/(dashboard)/audit/page.tsx (add)
- apps/admin/src/app/(dashboard)/_nav.ts (nav item)
- apps/admin/src/test/audit.test.tsx (add)
- apps/admin/src/test/sidebar.test.tsx (live-pages assertion)

## 15. Notes for the implementing agent
- Backend endpoint already has audit entries from T-002 writer (called by T-003+ on every action).
