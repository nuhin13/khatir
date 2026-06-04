---
id: T-004
epic: EPIC-14
title: OCR provider impl (in gateway)
layer: infra
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · OCR provider impl (in gateway)

## 1. Feature goal
Concrete OCR provider HTTP client (Google Cloud Vision or configured provider). Accepts image bytes, returns ExtractedTenant JSON. Key from AIProvider config. Tests (mocked HTTP).

## 2. Business logic
Concrete OCR provider HTTP client (Google Cloud Vision or configured provider). Accepts image bytes, returns ExtractedTenant JSON. Key from AIProvider config. Tests (mocked HTTP).

## 3. What this task DOES
See feature goal. Implements the above in the correct layer (infra=gateway, backend=Django).

## 5. Files & changes
### Add/Update
- Relevant files per layer; tests.

## 6–10.
No new DB tables (beyond T-001). External: AI vendor APIs (mocked in tests). No feature flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation — GoogleVisionOcrProvider (HTTPProvider subclass) + ExtractedTenant DTO
- [x] Tests (mocked external) — httpx.MockTransport, 11 tests
- [x] ruff + mypy clean (gateway)

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tests + lint pass.
## 14. Self-review
- [x] API keys from config; not logged (api_key from ProviderConfig, sent as Vision query param, never in body/logs; only normalized DTO crosses the call boundary — raw payload + plaintext NID never logged)
### Deviations from spec
- Provider targets Google Cloud Vision `images:annotate` (DOCUMENT_TEXT_DETECTION)
  by default; `endpoint_url` can point at a compatible backend. API key passed as
  the Vision `?key=` query param (its auth scheme), not a bearer header.
- Gateway-side `ExtractedTenant`/`ExtractedField` dataclasses mirror the Django
  DTO (`khatir.tenants.extraction.dto`); `dob` normalized to an ISO `YYYY-MM-DD`
  string so it survives JSON transport. `.to_dict()` yields the JSON envelope.
- `GoogleVisionOcrProvider` subclasses `HTTPProvider` and overrides `call()` so
  the existing `ProviderRouter` dispatches it unchanged; `build_ocr_provider`
  factory mirrors the asr/chat convention.
- Unreadable image → empty `ExtractedTenant` (valid outcome); a Vision per-image
  `error` or transport failure → `ProviderError` so the router fails over.
### Files touched (actual)
- services/ai-gateway/providers/ocr.py (new)
- services/ai-gateway/providers/__init__.py (additive exports)
- services/ai-gateway/tests/test_ocr.py (new, 11 tests, mocked HTTP)
## 15. Notes
Concrete OCR provider HTTP client (Google Cloud Vision or configured provider). Accepts image bytes, returns ExtractedTenant JSON. Key from AIProvider config. Tests (mocked HTTP).
