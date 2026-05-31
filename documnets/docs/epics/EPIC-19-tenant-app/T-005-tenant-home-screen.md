---
id: T-005
epic: EPIC-19
title: Tenant home screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-02.T-004, T-002]
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

# T-005 · Tenant home screen

## 1. Feature goal
Tenant role home: rent status (due/paid this month), quick actions (pay, view lease, report issue), recent activity. Fills the EPIC-02 tenant shell Home placeholder.

## 2. Business logic
Tenant role home: rent status (due/paid this month), quick actions (pay, view lease, report issue), recent activity. Fills the EPIC-02 tenant shell Home placeholder. Per `tenHome` design.

## 3. What this task DOES
- tenHome_screen matching the `tenHome` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenHome_screen.dart; ARB; test
### Update
- router `/tenant/home`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenHome` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenHome')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/home`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_home_rent_status, ten_home_pay, ten_home_lease, ten_home_report (bn + en) — lift copy from `tenHome`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenHome_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/home` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenHome_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenHome` design; tenant-scoped; all states.
- [ ] **Screen `tenHome` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Tenant role home: rent status (due/paid this month), quick actions (pay, view lease, report issue), recent activity. Fills the EPIC-02 tenant shell Home placeholder.
