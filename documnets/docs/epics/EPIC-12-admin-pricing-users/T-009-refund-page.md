---
id: T-009
epic: EPIC-12
title: Refund queue page (Next.js)
layer: admin
size: S
status: todo
preferred_agent: codex
depends_on: [T-004]
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

# T-009 · Refund queue page (Next.js)

## 1. Feature goal
Simple table for finance staff to view and process pending refund requests.

## 2. Business logic
List of pending payment intents; each row: user, tier, amount, date; actions: Approve (reason) + Deny (reason). Finance+super.

## 3. What this task DOES
- /billing/refunds page; action dialogs. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/billing/refunds/page.tsx; test

## 6–10.
No DB; consumes refund endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/billing/refunds`
- Refund table + approve/deny dialogs

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] refund table (pending)
- [ ] approve/deny dialogs (reason)
- [ ] finance+super gate
- [ ] test: renders, action fires
- [ ] tsc pass

## 12. Test plan
### Automated
- refund_page renders; approve dialog fires
## 13. Acceptance criteria
- [ ] Refund queue page; approve/deny; tests pass.
## 14. Self-review
- [ ] Reason required; finance+super
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Simple for MVP. MFS integration trails.
