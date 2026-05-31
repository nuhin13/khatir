---
id: T-016
epic: EPIC-04
title: Tenant save + route to DMP (wire all 3 paths)
layer: mobile
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-011, T-012, T-013, T-014]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] saveTenantAndContinue (create + family + photo_ref)
- [ ] success → DMP route (placeholder until EPIC-05)
- [ ] free-tier status surfaced
- [ ] error handling
- [ ] all 3 review screens call it
- [ ] test (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- save_tenant_test → create called with merged fields; navigates to DMP
### Manual QA
1. OCR → review → save → DMP screen (or placeholder).

## 13. Acceptance criteria
- [ ] All 3 paths save tenant + route to DMP; errors handled.
- [ ] EPIC-04 add-tenant flow works end-to-end.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Single convergent save (no per-path duplication)
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- DMP route target is built in EPIC-05; until then route to a placeholder screen. This task is the EPIC-04 validation gate.
