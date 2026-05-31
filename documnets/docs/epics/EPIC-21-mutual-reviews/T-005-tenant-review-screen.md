---
id: T-005
epic: EPIC-21
title: Flutter tenant review screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-19.T-011, T-002]
blocks: []
external_services: []
feature_flags: [reviews_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Flutter tenant review screen

## 1. Feature goal
The `tenReview` screen: a tenant privately rates/reviews their landlord, with clear "private, not public" messaging.

## 2. Business logic
Per `tenReview` design (star rating + comment, go('tenHome')). Submit → backend (T-002). Shows reviews about the tenant only after double-blind reveal. Kill-switch off → hidden. Prominent privacy disclaimer.

## 3. What this task DOES
- tenReview_screen matching `tenReview`; rating + comment + submit; reveal display; disclaimer; states. Widget test.

## 5. Files & changes
### Add
- features/reviews/presentation/screens/tenant_review_screen.dart; ARB; test
### Update
- router /tenant/review; tenant home wiring

## 6–10.
No DB; consumes review endpoints; mobile 🟢; flag reviews_feature.

## 8. UI changes
- **Design source:** screen `tenReview` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('tenReview')`)
- Surface: mobile · **Lane:** 🟢 mobile (tenant)
- Route: `/tenant/review`
- Translate star rating + comment + disclaimer; values from packages/design-tokens
- States: data / submitting / submitted / revealed / flag-off (hidden)
- i18n keys: `ten_review_rate`, `ten_review_comment`, `ten_review_submit`, `ten_review_private`, `ten_review_disclaimer` (bn + en)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] tenReview_screen matches design (star rating + comment)
- [ ] submit → backend
- [ ] reveal display (double-blind)
- [ ] prominent "private, not public" disclaimer
- [ ] kill-switch off → hidden
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- tenant_review_test → submit fires; disclaimer present; flag-off hides
### Manual QA
1. Tenant rates landlord → private confirmation. Kill-switch off → feature gone.

## 13. Acceptance criteria
- [ ] tenReview matches design; private messaging prominent; kill-switch respected.
- [ ] **Screen `tenReview` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] "Private, never public" prominent; tokens
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Copy must never imply the review is published or browseable by others.
