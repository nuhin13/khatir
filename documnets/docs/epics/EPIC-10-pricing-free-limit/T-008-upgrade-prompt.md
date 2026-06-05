---
id: T-008
epic: EPIC-10
title: Upgrade prompt (limit reached)
layer: mobile
size: S
status: done
preferred_agent: codex
depends_on: [T-007]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Upgrade prompt (limit reached)

## 1. Feature goal
Show a friendly upgrade prompt when a landlord tries to add a 3rd tenant on the free tier — intercept the `tier_limit_exceeded` error and route to the plan screen.

## 2. Business logic
When EPIC-04's add-tenant call returns tier_limit_exceeded: show a bottom sheet / dialog explaining the limit, with "Upgrade plan" → /settings/plan and "Not now" dismiss.

## 3. What this task DOES
- Intercept tier_limit_exceeded in add-tenant controller → show upgrade bottom sheet. Widget test.

## 5. Files & changes
### Add
- features/billing/presentation/widgets/upgrade_prompt.dart; ARB; test
### Update
- add-tenant flow to handle the error

## 6–10.
No DB; no API (error handling); surface mobile 🟢; no external; no flags.

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- Upgrade bottom sheet (triggered by limit error)
- States: shown / dismissed
- Navigation: upgrade → /settings/plan
- i18n keys: `upgrade_title`, `upgrade_body`, `upgrade_cta`, `upgrade_later` (bn + en)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] upgrade_prompt bottom sheet
- [x] triggered by tier_limit_exceeded
- [x] upgrade → /settings/plan; dismiss closes
- [x] ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- upgrade_prompt_test → renders; upgrade routes; dismiss closes
### Manual QA
1. Hit limit → prompt appears → tap upgrade → plan screen.

## 13. Acceptance criteria
- [x] Upgrade prompt appears on limit; routes to plan; test passes.
## 14. Self-review
- [x] Friendly copy; tokens; dismissable
### Deviations from spec
- The mobile `ApiException` did not surface the backend error-envelope `code`,
  so I added an `errorCode` field parsed from the `{"error":{"code":...}}`
  envelope (`api_exception.dart`). The save controller branches on
  `errorCode == 'tier_limit_exceeded'` rather than scraping the message — this
  is the same intercept pattern T-009 reuses for `feature_requires_upgrade`.
- The intercept lives in the shared `TenantSaveController` (the single
  save+route action for all three add-tenant intake paths, EPIC-04 T-016), so
  the prompt fires from OCR / voice / manual without per-path duplication.
### Files touched (actual)
- Add: `apps/mobile/lib/features/billing/presentation/widgets/upgrade_prompt.dart`
- Add: `apps/mobile/test/upgrade_prompt_test.dart`
- Update: `apps/mobile/lib/core/network/api_exception.dart` (errorCode from envelope)
- Update: `apps/mobile/lib/features/tenants/presentation/controllers/tenant_save_controller.dart` (intercept tier_limit_exceeded → UpgradePrompt.show)
- Update: `apps/mobile/lib/l10n/app_en.arb`, `apps/mobile/lib/l10n/app_bn.arb` (upgrade_* keys)
## 15. Notes
- The More screen's plan chip ("Free 1/2") is wired by EPIC-02 T-007. This task handles the intercept, not the chip.
