---
id: T-016
epic: EPIC-04
title: Tenant save + route to DMP (wire all 3 paths)
layer: mobile
size: S
status: done
preferred_agent: claude-code
depends_on: [T-011, T-012, T-013, T-014]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-016 · Tenant save + route to DMP (wire all 3 paths)

## 1. Feature goal
The shared save action that persists the tenant (from OCR/voice/manual review) and routes to the DMP form, completing the add-tenant flow.

## 2. Business logic
All three paths converge here: createTenant(fields + family + photo_ref) → on success, navigate to the DMP screen for that tenant (EPIC-05). Show free-tier status (1/2) if relevant. Handle errors.

## 3. What this task DOES
- A `saveTenantAndContinue` controller action used by all review screens; success → `/dmpform/{tenantId}` (placeholder until EPIC-05); error handling; free-tier toast. Widget/integration test.

## 5. Files & changes
### Add
- tenants save controller; test
### Update
- T-011/012/013 proceed buttons call this

## 6. Database changes
None.
## 7. API changes
Consumes POST /tenants.

## 8. UI changes
- Surface: mobile · **Lane:** 🟢 mobile
- No new screen; the convergent save+route action
- States: saving (loading), success (→ DMP), error
- Navigation: success → `/dmpform/:tenantId` (EPIC-05; placeholder until then)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] saveTenantAndContinue (create + family + photo_ref)
- [x] success → DMP route (placeholder until EPIC-05)
- [x] free-tier status surfaced
- [x] error handling
- [x] all 3 review screens call it
- [x] test (mocked)
- [x] analyze + test pass

## 12. Test plan
### Automated
- save_tenant_test → create called with merged fields; navigates to DMP
### Manual QA
1. OCR → review → save → DMP screen (or placeholder).

## 13. Acceptance criteria
- [x] All 3 paths save tenant + route to DMP; errors handled.
- [x] EPIC-04 add-tenant flow works end-to-end.
- [x] Test + analyze pass.

## 14. Self-review
- [x] Single convergent save (no per-path duplication)
### Deviations from spec
- Free-tier status (T-008) is surfaced opportunistically: T-008 is a backend
  task and is NOT a dependency, and the masked create response carries no usage
  fields today. The save action parses optional `{tenants_used, free_limit,
  is_over_free}` from the create response (TenantUsage.maybeFromJson) and shows
  the "1/2 free" toast only when present, degrading to no toast otherwise — so
  it lights up automatically once the backend echoes usage, with no client
  change.
- DMP route target is a placeholder (DmpPlaceholderScreen at `/dmpform/:tenantId`)
  per §15 — EPIC-05 replaces it with the real police-form screen.
- `onProceed` on the OCR-review and manual screens is kept as a test seam: when
  supplied (widget tests) it short-circuits the network save; when null (the
  router) the screen runs the shared TenantSaveController. This preserves the
  existing T-011/T-013 widget tests unchanged.
### Files touched (actual)
- features/tenants/data/models/tenant_create_result.dart (TenantUsage + TenantCreateResult; new)
- features/tenants/data/tenant_repository.dart (createTenantDetailed; createTenant delegates)
- features/tenants/data/tenants_providers.dart (UnitTenantsController.createDetailed)
- features/tenants/presentation/controllers/tenant_save_controller.dart (TenantSaveDraft + TenantSaveController; new)
- features/tenants/presentation/screens/dmp_placeholder_screen.dart (DMP placeholder; new)
- features/tenants/presentation/screens/ocr_review_screen.dart (proceed runs save + loading state)
- features/tenants/presentation/screens/manual_tenant_screen.dart (proceed runs save + loading state)
- core/router/app_router.dart (DMP route; OCR-review/manual wired to real save)
- l10n/app_bn.arb + l10n/app_en.arb (tenant_save_error, tenant_free_tier_status, dmp_placeholder_*)
- test/save_tenant_test.dart (new; 5 widget tests)

## 15. Notes for the implementing agent
- DMP route target is built in EPIC-05; until then route to a placeholder screen. This task is the EPIC-04 validation gate.
