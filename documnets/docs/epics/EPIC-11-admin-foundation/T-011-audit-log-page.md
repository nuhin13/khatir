---
id: T-011
epic: EPIC-11
title: Audit log viewer page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002, T-008]
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
- [ ] backend GET /audit-log (paginated, filterable)
- [ ] audit_table component (filters + pagination)
- [ ] before/after JSON diff expander
- [ ] compliance role access
- [ ] no delete/edit on entries
- [ ] tests: render, filter, pagination
- [ ] eslint + tsc pass

## 12. Test plan
### Automated
- audit_log_page renders; filter changes query
### Manual QA
1. Admin action → appears in audit log with diff.

## 13. Acceptance criteria
- [ ] Audit log viewer; filterable; diff expander; compliance role; no delete; tests pass.
## 14. Self-review
- [ ] Immutable; compliance-accessible
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Backend endpoint already has audit entries from T-002 writer (called by T-003+ on every action).
