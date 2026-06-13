---
id: T-007
epic: EPIC-12
title: Users list + search page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003, EPIC-11.T-008]
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
- [x] search form (phone/name/id)
- [x] paginated user table
- [x] click → user detail
- [x] ops+super route guard
- [x] TanStack Query; states
- [x] test: search renders results
- [x] tsc pass

## 12. Test plan
### Automated
- users_page renders table; search updates query
## 13. Acceptance criteria
- [x] User search + list page; navigates to detail; tests pass.
## 14. Self-review
- [x] Masked phone in table; ops+super only
### Deviations from spec
- The `Tier` column renders `—`: the backend search projection
  (`AdminUserListSerializer`, T-003) does not carry the subscription tier (it is
  loaded on the detail page T-008), so the list cannot fabricate it. Column kept
  for spec §4.2 parity; value filled when/if the list endpoint adds tier.
- Route guard is ops + support + super (not "ops + super" as the §11 shorthand
  reads): the backend `IsUsersReadAdmin` gate (T-003) grants read to support
  too, and spec §2.1 makes support read-only on user records — the page mirrors
  that gate exactly.
### Files touched (actual)
- Add: apps/admin/src/lib/api/users.ts
- Add: apps/admin/src/components/admin/users_table.tsx
- Add: apps/admin/src/components/admin/users_browser.tsx
- Update: apps/admin/src/app/(dashboard)/users/page.tsx (replaced ComingSoon)
- Update: apps/admin/src/app/(dashboard)/_nav.ts (Users de-flagged comingSoon)
- Add: apps/admin/src/test/users.test.tsx
- Update: apps/admin/src/test/sidebar.test.tsx (Users → live-pages set)
## 15. Notes
- Phone shown masked in list view.
