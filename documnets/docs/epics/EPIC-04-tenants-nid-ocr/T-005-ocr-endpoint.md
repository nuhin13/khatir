---
id: T-005
epic: EPIC-04
title: OCR endpoint (image → fields)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-010]
external_services: [ocr]
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · OCR endpoint (image → fields)

## 1. Feature goal
`POST /tenants/ocr` accepts an NID image, stores it encrypted, runs OCR via the provider, returns normalized editable fields (does not create the tenant yet).

## 2. Business logic
Image stored encrypted (T-003); OCR via TenantExtractionProvider (T-004); return ExtractedTenant + the stored photo_ref. May run async (Celery) for large images but can be sync for MVP. Never returns raw provider payload.

## 3. What this task DOES
- Endpoint (multipart image) → store encrypted → extract → return fields + photo_ref.
- Permission: landlord/manager. Rate-limit (cost). Tests with mocked provider.

## 5. Files & changes
### Add
- tenants/views.py (ocr view), serializers, tests/test_ocr_endpoint.py
### Update
- tenants/urls.py, config/urls.py

## 6. Database changes
None (tenant not yet created). Image stored in object storage.

## 7. API changes
| Method | Path | Auth | Status |
|--------|------|------|--------|
| POST | /api/v1/tenants/ocr | landlord/mgr | 200 |

## 8. UI changes
No UI (consumed by T-010/011).
## 9. External services
OCR provider.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] multipart image intake
- [x] store encrypted (T-003) → photo_ref
- [x] extract via provider → fields
- [x] return fields + photo_ref (no raw payload)
- [x] permission + rate-limit
- [x] Tests (mocked provider)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_ocr_returns_fields, test_image_stored_encrypted, test_requires_landlord, test_rate_limited
### Manual QA
1. POST an NID image → fields + photo_ref returned.

## 13. Acceptance criteria
- [x] OCR endpoint returns editable fields + encrypted photo_ref; tests + lint pass.

## 14. Self-review
- [x] Image encrypted; no raw payload returned/logged
### Deviations from spec
- Intake uses a DRF `FileField` (not `ImageField`) so no Pillow dependency is
  pulled in just to gate uploads; the OCR provider owns byte interpretation.
- `config/urls.py` already includes `tenants.urls`, so only `tenants/urls.py`
  needed a route (`tenants/ocr`, declared before the router so it does not
  collide with the viewset's `tenants/<pk>` detail route).
- Rate-limit is a per-user DRF `ScopedRateThrottle`-style class
  (`tenant_ocr` scope, default `30/hour`, env-tunable via `THROTTLE_TENANT_OCR`),
  matching the existing auth-throttle pattern; 429 → standard `rate_limited`
  envelope via the core exception handler.
- Sync (not Celery) extraction, accepted for MVP per §15.
### Files touched (actual)
- apps/api/khatir/tenants/views.py — `TenantOcrView`
- apps/api/khatir/tenants/serializers.py — `OcrRequestSerializer`/`OcrResponseSerializer`
- apps/api/khatir/tenants/throttling.py — `OcrUserThrottle` (new)
- apps/api/khatir/tenants/urls.py — `tenants/ocr` route
- apps/api/config/settings/base.py — `tenant_ocr` throttle rate
- apps/api/khatir/tenants/tests/test_ocr_endpoint.py — tests (new)

## 15. Notes for the implementing agent
- Keep extraction provider-agnostic (T-004). Consider Celery if provider latency is high; sync is acceptable for MVP with a reasonable timeout.
