---
id: T-007
epic: EPIC-19
title: Tenant in-app pay screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: [tenant_app_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Tenant in-app pay screen

## 1. Feature goal
In-app rent payment: shows amount due, pay instructions (bKash/Nagad), submit proof (txn id / screenshot) — feeds the same EPIC-07 pipeline. On submit → pending verification → receipt when verified.

## 2. Business logic
In-app rent payment: shows amount due, pay instructions (bKash/Nagad), submit proof (txn id / screenshot) — feeds the same EPIC-07 pipeline. On submit → pending verification → receipt when verified. Per `tenPay` design.

## 3. What this task DOES
- tenPay_screen matching the `tenPay` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenPay_screen.dart; ARB; test
### Update
- router `/tenant/pay/:id`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenPay` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenPay')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/pay/:id`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_pay_amount, ten_pay_instructions, ten_pay_submit, ten_pay_pending (bn + en) — lift copy from `tenPay`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenPay_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/pay/:id` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenPay_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenPay` design; tenant-scoped; all states.
- [ ] **Screen `tenPay` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only
### Deviations from spec
### Files touched (actual)
## 15. Notes
In-app rent payment: shows amount due, pay instructions (bKash/Nagad), submit proof (txn id / screenshot) — feeds the same EPIC-07 pipeline. On submit → pending verification → receipt when verified.
