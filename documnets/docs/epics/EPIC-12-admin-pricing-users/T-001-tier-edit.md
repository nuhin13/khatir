---
id: T-001
epic: EPIC-12
title: Tier edit endpoints (impact preview)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-10.T-001, EPIC-11.T-002]
blocks: [T-002, T-005]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Tier edit endpoints (impact preview)

## 1. Feature goal
Let admin staff edit a pricing tier's values and see the impact (subscribers affected, revenue delta) before applying.

## 2. Business logic
GET /admin/api/pricing/tiers → list all. PATCH /{key} → requires reason; calculates preview (subscribers count + estimated revenue delta); applies; admin audit (before/after JSON); invalidates /config/public cache. Finance+super role only.

## 3. What this task DOES
- List + edit endpoints; impact preview calculation; reason required; admin audit; role gate; tests.

## 5. Files & changes
### Add
- admin_portal/pricing_views.py, serializers, tests/test_pricing_admin.py
### Update
- admin_portal/urls.py

## 6. Database changes
Writes PricingTier rows.
## 7. API changes
| GET | /admin/api/pricing/tiers | admin | 200 |
| PATCH | /admin/api/pricing/tiers/{key} | finance/super | 200 |
| POST | /admin/api/pricing/tiers/{key}/preview | finance/super | 200 |

## 8. UI changes
No UI (T-005 builds it).
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] list all tiers
- [ ] preview endpoint (subscribers affected, revenue delta)
- [ ] PATCH with reason required
- [ ] select_for_update on edit
- [ ] admin audit (before/after)
- [ ] bust /config/public cache after write (T-002)
- [ ] finance+super role gate
- [ ] Tests: edit, preview, audit, role gate
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_edit_tier, test_preview, test_audit_entry, test_role_gate
### Manual QA
1. Preview a price change → see subscriber count. Apply → reflected.

## 13. Acceptance criteria
- [ ] Tier edit + preview + audit + role gate; cache busted; tests + lint pass.

## 14. Self-review
- [ ] Reason required; before/after in audit; finance+super only
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Preview is read-only (no write). Keep it as a separate endpoint so the UI can call it before showing the confirm dialog.
