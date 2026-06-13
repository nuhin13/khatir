---
id: T-006
epic: EPIC-19
title: Tenant lease view screen
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

# T-006 · Tenant lease view screen

## 1. Feature goal
Read-only view of the tenant's current lease: rent, advance, dates, landlord contact, terms. If an AI lease document exists (EPIC-18), link to view the PDF.

## 2. Business logic
Read-only view of the tenant's current lease: rent, advance, dates, landlord contact, terms. If an AI lease document exists (EPIC-18), link to view the PDF. Per `tenLease` design.

## 3. What this task DOES
- tenLease_screen matching the `tenLease` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenLease_screen.dart; ARB; test
### Update
- router `/tenant/lease`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenLease` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenLease')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/lease`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_lease_rent, ten_lease_dates, ten_lease_landlord, ten_lease_document (bn + en) — lift copy from `tenLease`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenLease_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/lease` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenLease_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenLease` design; tenant-scoped; all states.
- [ ] **Screen `tenLease` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Read-only view of the tenant's current lease: rent, advance, dates, landlord contact, terms. If an AI lease document exists (EPIC-18), link to view the PDF.
