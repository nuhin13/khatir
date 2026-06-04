---
id: T-009
epic: EPIC-14
title: Admin AI providers endpoints
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-002]
blocks: [T-011, T-012]
external_services: []
feature_flags: []
started_at: 2026-06-04
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Admin AI providers endpoints

## 1. Feature goal
CRUD + test-connection for AI provider configs; DPA constraint for NID OCR; usage read endpoint.

## 2. Business logic
GET/POST/PATCH /admin/api/ai-providers. DPA rule: if category=ocr and provider endpoint is non-BD → dpa_reference required before save. POST /{id}/test-connection → call gateway to verify creds. GET /admin/api/ai-usage (aggregated). Super+ops.

## 3. What this task DOES
- Provider CRUD + DPA validation + test-connection + usage endpoint; admin audit; tests.

## 5. Files & changes
### Add
- ai_providers/admin_views.py, serializers, tests/test_providers_admin.py
### Update
- admin_portal/urls.py

## 6. Database changes
Writes AIProvider rows.
## 7. API changes
| GET/POST/PATCH | /admin/api/ai-providers | super/ops | 200/201 |
| POST | /admin/api/ai-providers/{id}/test-connection | super/ops | 200 |
| GET | /admin/api/ai-usage | super/ops | 200 |

## 8–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] CRUD (api_key encrypted on save) — `ad`
- [x] DPA constraint (ocr + non-BD → dpa_reference required) — `ad`
- [x] test-connection (calls gateway) — `ad`
- [x] usage endpoint (aggregated from AIUsageLog) — `ad`
- [x] admin audit — `ad`
- [x] super+ops gate — `ad`
- [x] Tests: CRUD, DPA gate, test-connection, usage — `ad`
- [x] ruff + mypy clean — `ad`

## 12. Test plan
### Automated
- test_create_provider, test_dpa_required_for_ocr, test_connection_ok
## 13. Acceptance criteria
- [x] Provider CRUD + DPA constraint + test-connection; audited; tests + lint pass.
## 14. Self-review
- [x] API key encrypted; DPA enforced; audit present
### Deviations from spec
- PATCH detail route plus dedicated test-connection + usage views live in
  `ai_providers/admin_views.py`; URL wiring is in `admin_portal/admin_urls.py`
  (not `urls.py`) where all admin-portal routes are registered.
### Files touched (actual)
- khatir/ai_providers/admin_views.py
- khatir/ai_providers/serializers.py
- khatir/ai_providers/tests/test_providers_admin.py
- khatir/admin_portal/admin_urls.py
## 15. Notes
- DPA rule: any non-BD OCR provider (based on endpoint domain) requires a dpa_reference. Enforce at serializer validation.
