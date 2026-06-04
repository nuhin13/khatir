---
id: T-005
epic: EPIC-12
title: Pricing editor page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-008]
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

# T-005 · Pricing editor page (Next.js)

## 1. Feature goal
A table of all pricing tiers where finance staff can edit values, see the impact, and apply changes with a reason.

## 2. Business logic
Inline-editable tier table; "Preview impact" button calls T-001 preview; confirmation dialog with impact + reason field; apply; change reflected <60s. Finance+super only (route guard).

## 3. What this task DOES
- /pricing page; editable table; preview modal; reason + confirm; TanStack Query. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/pricing/page.tsx, components/admin/tier_table.tsx; test
### Update
- sidebar nav "Pricing" → /pricing

## 6–10.
No DB; consumes pricing endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Pricing Editor + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/pricing`
- Editable tier table + preview modal + reason field
- States: loading / editing / previewing / saving

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tier table with inline edit
- [ ] preview modal (calls preview endpoint)
- [ ] reason field + confirm dialog
- [ ] apply → refetch after 2s (cache busted)
- [ ] finance+super route guard
- [ ] TanStack Query; loading + error states
- [ ] test: render, edit, preview, confirm
- [ ] eslint + tsc pass

## 12. Test plan
### Automated
- pricing_page renders tiers; edit calls preview; confirm calls patch
### Manual QA
1. Edit a price → preview shows subscribers → confirm with reason → reflected.

## 13. Acceptance criteria
- [ ] Pricing editor works end-to-end; preview + reason required; tests pass.
## 14. Self-review
- [ ] Finance+super gate; refetches after change
### Deviations from spec
### Files touched (actual)
## 15. Notes
- T-006 is the impact preview widget extracted as a reusable component.
