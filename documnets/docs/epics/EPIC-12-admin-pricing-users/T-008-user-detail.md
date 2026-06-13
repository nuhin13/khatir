---
id: T-008
epic: EPIC-12
title: User detail + actions page (Next.js)
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

# T-008 · User detail + actions page (Next.js)

## 1. Feature goal
Full user profile with subscription, usage, audit trail, and action buttons (suspend/reactivate/upgrade).

## 2. Business logic
Loads /admin/users/{id}. Shows: profile, tier + usage, subscription history, recent actions, audit trail. Action buttons: suspend (requires reason), reactivate, manual upgrade. All confirm dialogs with reason. Ops+super.

## 3. What this task DOES
- /users/[id] page; action dialogs; audit trail section. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/users/[id]/page.tsx; test

## 6–10.
No DB; consumes user detail + action endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §User Detail + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/users/[id]`
- Profile + subscription + audit trail + action buttons
- States: loading / active / suspended

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] profile + tier + usage sections
- [x] audit trail (recent admin actions)
- [x] suspend dialog (reason required)
- [x] reactivate + upgrade buttons
- [x] all actions confirm + refetch
- [x] ops+super gate
- [x] tests: render, action dialogs fire
- [x] tsc pass

## 12. Test plan
### Automated
- user_detail renders profile + audit; suspend opens dialog
## 13. Acceptance criteria
- [x] User detail + all actions; reason required; tests pass.
## 14. Self-review
- [x] Reason required; audit trail visible; role-gated
### Deviations from spec
- Read access is ops+support+super (mirrors backend `IsUsersReadAdmin`, T-003 —
  support is read-only per spec §2.1); the write actions (suspend / reactivate /
  upgrade) are ops+super only (`IsUsersWriteAdmin`). The server page passes
  `canWrite` so a support viewer sees the full profile but no action buttons.
- The compact `AdminUserListSerializer` carries no tier; the tier is shown from
  the separate `subscription` object in the detail envelope. The upgrade dialog
  loads the tier list via the existing T-005 `fetchPricingTiers`.
### Files touched (actual)
- Add: apps/admin/src/app/(dashboard)/users/[id]/page.tsx (server role guard +
  back link), apps/admin/src/components/admin/user_detail.tsx (detail island:
  profile/subscription/usage/audit sections + suspend/reactivate/upgrade confirm
  dialogs with reason), apps/admin/src/test/user-detail.test.tsx (8 RTL tests).
- Update: apps/admin/src/lib/api/users.ts (zod schemas + fetchUserDetail /
  suspendUser / reactivateUser / upgradeSubscription consuming T-003 endpoints).
## 15. Notes
- After suspend → user detail shows suspended status badge immediately.
