---
id: T-007
epic: EPIC-12
title: Users list + search page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, EPIC-11.T-008]
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

# T-007 · Users list + search page (Next.js)

## 1. Feature goal
A searchable, paginated user list for ops staff — find any user by phone, name, or ID.

## 2. Business logic
Search form → GET /admin/users. Paginated table with columns: name, phone (masked), role, tier, status. Click row → T-008 user detail. Ops+super route guard.

## 3. What this task DOES
- /users page; search form; paginated table; TanStack Query. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/users/page.tsx; test
### Update
- sidebar "Users" → /users

## 6–10.
No DB; consumes /admin/users; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Users + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/users`
- Search form + paginated table
- States: loading / empty / data

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] search form (phone/name/id)
- [ ] paginated user table
- [ ] click → user detail
- [ ] ops+super route guard
- [ ] TanStack Query; states
- [ ] test: search renders results
- [ ] tsc pass

## 12. Test plan
### Automated
- users_page renders table; search updates query
## 13. Acceptance criteria
- [ ] User search + list page; navigates to detail; tests pass.
## 14. Self-review
- [ ] Masked phone in table; ops+super only
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Phone shown masked in list view.
