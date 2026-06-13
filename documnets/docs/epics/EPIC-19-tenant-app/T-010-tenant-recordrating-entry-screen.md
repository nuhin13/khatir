---
id: T-010
epic: EPIC-19
title: Tenant record/rating entry screen
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

# T-010 · Tenant record/rating entry screen

## 1. Feature goal
Private record where a tenant can note/rate their tenancy experience (rating + private notes + consent toggle). Feeds EPIC-21 mutual reviews. STRICTLY PRIVATE — never public; consent-gated for any sharing.

## 2. Business logic
Private record where a tenant can note/rate their tenancy experience (rating + private notes + consent toggle). Feeds EPIC-21 mutual reviews. STRICTLY PRIVATE — never public; consent-gated for any sharing. Per `tenRecord` design.

## 3. What this task DOES
- tenRecord_screen matching the `tenRecord` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenRecord_screen.dart; ARB; test
### Update
- router `/tenant/record`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenRecord` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenRecord')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/record`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_record_rating, ten_record_notes, ten_record_consent, ten_record_save (bn + en) — lift copy from `tenRecord`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenRecord_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/record` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenRecord_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenRecord` design; tenant-scoped; all states.
- [ ] **Screen `tenRecord` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only; strictly private (never public)
### Deviations from spec
### Files touched (actual)
## 15. Notes
Private record where a tenant can note/rate their tenancy experience (rating + private notes + consent toggle). Feeds EPIC-21 mutual reviews. STRICTLY PRIVATE — never public; consent-gated for any sharing.
