---
id: T-004
epic: EPIC-04
title: TenantExtractionProvider interface (OCR/ASR abstraction)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-005, T-006]
external_services: [ocr, asr]
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · TenantExtractionProvider interface (OCR/ASR abstraction)

## 1. Feature goal
A thin provider interface for extracting tenant fields from an NID image (OCR) or Bangla audio (ASR), so the concrete provider can be swapped — and later routed through the AI gateway (EPIC-14) — without touching endpoints or screens.

## 2. Business logic
Interface returns a normalized `ExtractedTenant` (name, nid_number, dob, address, confidence per field if available). Concrete impls call the chosen OCR/ASR provider (creds from env / config). EPIC-14 will replace the impl with an AI-gateway-backed one.

## 3. What this task DOES
- `tenants/extraction/base.py`: `TenantExtractionProvider` ABC (`extract_from_image`, `extract_from_audio`).
- One concrete OCR impl + one ASR impl (provider per `ocr_provider_key`/`asr_provider_key` config).
- Normalized DTO. Tests with mocked provider responses.

## 5. Files & changes
### Add
- `khatir/tenants/extraction/{base,ocr_provider,asr_provider,dto}.py`
- tests/test_extraction.py
### Update
- none

## 6. Database changes
None.
## 7. API changes
None (used by T-005/006).
## 8. UI changes
No UI.
## 9. External services
OCR + ASR providers (env creds). Mockable.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] TenantExtractionProvider ABC
- [x] ExtractedTenant DTO (fields + optional confidence)
- [x] OCR impl (image → fields)
- [x] ASR impl (audio → fields)
- [x] provider selected via config
- [x] Tests (mocked)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_ocr_extract_normalizes, test_asr_extract_normalizes, test_provider_selection
### Manual QA
1. Feed a sample image to the OCR impl (or mock) → normalized fields.

## 13. Acceptance criteria
- [x] Swappable extraction interface with OCR + ASR impls; tests + lint pass.

## 14. Self-review
- [x] Interface generic; EPIC-14-ready; store result not raw payload
### Deviations from spec
- Added a small `extraction/normalize.py` (pure field coercers) shared by both
  providers to avoid duplicating name/NID/date normalization; and an
  `extraction/__init__.py` re-exporting the public surface. No DB changes.
- Provider selection reads `ocr_provider_key` / `asr_provider_key` via
  `core.config.get_config` with a `"default"` fallback — no migration/seed
  needed (§6 says none), unknown/unset keys resolve to the built-in provider.
### Files touched (actual)
- khatir/tenants/extraction/{__init__,base,dto,normalize,ocr_provider,asr_provider}.py
- khatir/tenants/tests/test_extraction.py

## 15. Notes for the implementing agent
- Return only the normalized result; never persist the raw provider payload (privacy). EPIC-14 swaps the impl to call services/ai-gateway over HTTP.
