---
id: T-009
epic: EPIC-19
title: Tenant receipts list screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-002]
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

# T-009 · Tenant receipts list screen

## 1. Feature goal
List of the tenant's rent receipts (paid periods) with download/share. Reuses receipt PDF (EPIC-07).

## 2. Business logic
List of the tenant's rent receipts (paid periods) with download/share. Reuses receipt PDF (EPIC-07). Per `tenReceipts` design.

## 3. What this task DOES
- tenReceipts_screen matching the `tenReceipts` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenReceipts_screen.dart; ARB; test
### Update
- router `/tenant/receipts`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenReceipts` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenReceipts')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/receipts`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_receipts_title, ten_receipts_period, ten_receipts_download, ten_receipts_empty (bn + en) — lift copy from `tenReceipts`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenReceipts_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/receipts` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenReceipts_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenReceipts` design; tenant-scoped; all states.
- [ ] **Screen `tenReceipts` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only
### Deviations from spec
### Files touched (actual)
## 15. Notes
List of the tenant's rent receipts (paid periods) with download/share. Reuses receipt PDF (EPIC-07).
