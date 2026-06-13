---
id: T-008
epic: EPIC-14
title: Retrofit EPIC-04 OCR through gateway
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-007, EPIC-04.T-005]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Retrofit EPIC-04 OCR through gateway

## 1. Feature goal
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.

## 2. Business logic
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.

## 3. What this task DOES
See feature goal. Implements the above in the correct layer (infra=gateway, backend=Django).

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No new DB tables (beyond T-001). External: AI vendor APIs (mocked in tests). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation — `GatewayOcrProvider` (`ocr_provider.py`) + `aiproxy_client.extract_nid`
- [x] Tests (mocked external) — gateway provider + `extract_nid` client tests; existing OCR endpoint tests unchanged
- [x] ruff clean (backend); full pytest green

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] API keys from config; not logged (vendor creds live in the gateway, not Django; the client only carries the internal token on the Authorization header. Image bytes/raw payload are never logged; only the normalized DTO crosses the boundary.)
### Deviations from spec
- The endpoint (`TenantOcrView`) is unchanged — it already calls
  `get_ocr_provider().extract_from_image(...)`. Rather than hardwire the call
  site to the gateway, T-008 registers a config-selectable `GatewayOcrProvider`
  (`ocr_provider_key = "gateway"`) so the swap is operational, the local
  `default` seam stays for tests/offline, and no endpoint/test contract changes.
- `aiproxy_client.extract_nid(image)` is added as a thin convenience over the
  committed `call_gateway("ocr", ...)` (T-007); it base64-encodes the image for
  JSON transport. The gateway returns the already-normalized per-field envelope
  (`{field: {value, confidence}}`, `dob` as ISO string), mapped to the local
  `ExtractedTenant` via `_normalize_gateway_payload` (re-applying the shared
  normalizers so the DTO type promises hold).
### Files touched (actual)
- apps/api/khatir/ai_providers/client.py — `extract_nid` helper
- apps/api/khatir/tenants/extraction/ocr_provider.py — `GatewayOcrProvider` + registry entry + gateway envelope normalizer
- apps/api/khatir/ai_providers/tests/test_client.py — `extract_nid` test
- apps/api/khatir/tenants/tests/test_extraction.py — gateway provider tests
## 15. Notes
Replace EPIC-04 T-005's direct provider call with aiproxy_client.extract_nid(image). Same endpoint contract; just the provider impl changes. Tests unchanged.
