---
id: T-005
epic: EPIC-20
title: Flutter warning screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-06.T-007, T-002]
blocks: [T-006]
external_services: []
feature_flags: [warnings_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Flutter warning screen

## 1. Feature goal
The `warning` screen: issue a private warning to a tenant (type, reason), generate the notice, with a clear "private between you and your tenant" message.

## 2. Business logic
Per `warning` design (go('unit') context). Type picker + reason → issue → notice PDF → share. Kill-switch off → screen/feature not shown. Privacy + legal disclaimer prominent.

## 3. What this task DOES
- warning_screen matching `warning`; issue form; disclaimer; states. Widget test.

## 5. Files & changes
### Add
- features/warnings/presentation/screens/warning_screen.dart; ARB; test
### Update
- router /lease/:id/warning; unit/lease detail "Issue warning" CTA (hidden if kill-switch off)

## 6–10.
No DB; consumes warning endpoints; mobile 🟢; flag warnings_feature.

## 8. UI changes
- **Design source:** screen `warning` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('warning')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/lease/:id/warning`
- Translate type picker + reason + disclaimer; values from packages/design-tokens
- States: data / issuing / issued / flag-off (hidden)
- i18n keys: `warning_type`, `warning_reason`, `warning_issue`, `warning_private_notice`, `warning_disclaimer` (bn + en)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] warning_screen matches design
- [ ] type picker + reason + issue
- [ ] prominent "private — not public" + legal disclaimer
- [ ] kill-switch off → feature hidden
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- warning_screen_test → issue fires; disclaimer present; flag-off hides
### Manual QA
1. Issue a warning → notice generated → share. Kill-switch off → CTA gone.

## 13. Acceptance criteria
- [ ] Warning screen matches design; private/disclaimer prominent; kill-switch respected.
- [ ] **Screen `warning` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] "Private" messaging prominent; never implies public/shared; tokens
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Copy must make clear this is a private notice to one's own tenant — NOT a public report or shared blacklist.
