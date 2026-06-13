---
id: T-008
epic: EPIC-19
title: Tenant maintenance report screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-004]
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

# T-008 · Tenant maintenance report screen

## 1. Feature goal
Report a maintenance issue: category, description, photo (emojiHero 🔧 'What needs fixing?'). Submits to the landlord's queue (reuse EPIC-08). Shows status of past reports.

## 2. Business logic
Report a maintenance issue: category, description, photo (emojiHero 🔧 'What needs fixing?'). Submits to the landlord's queue (reuse EPIC-08). Shows status of past reports. Per `tenMaint` design.

## 3. What this task DOES
- tenMaint_screen matching the `tenMaint` design; tenant-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/tenant/presentation/screens/tenMaint_screen.dart; ARB; test
### Update
- router `/tenant/maintenance`; tenant shell wiring

## 6–10.
No DB; consumes /me/ endpoints; mobile 🟢; flag tenant_app_enabled.

## 8. UI changes
- **Design source:** screen `tenMaint` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenMaint')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant role)
- Route: `/tenant/maintenance`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: ten_maint_category, ten_maint_describe, ten_maint_photo, ten_maint_submit (bn + en) — lift copy from `tenMaint`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenMaint_screen matches design
- [ ] tenant-scoped data (own only)
- [ ] all states (loading/error/empty/data)
- [ ] route `/tenant/maintenance` + tenant shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenMaint_test → renders; tenant-scoped
### Manual QA
1. Log in as tenant → navigate to this screen → correct own data.

## 13. Acceptance criteria
- [ ] Screen matches `tenMaint` design; tenant-scoped; all states.
- [ ] **Screen `tenMaint` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; own-data only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Report a maintenance issue: category, description, photo (emojiHero 🔧 'What needs fixing?'). Submits to the landlord's queue (reuse EPIC-08). Shows status of past reports.
