---
id: T-009
epic: EPIC-14
title: Admin AI providers endpoints
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-002]
blocks: [T-011, T-012]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
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
- [ ] CRUD (api_key encrypted on save)
- [ ] DPA constraint (ocr + non-BD → dpa_reference required)
- [ ] test-connection (calls gateway)
- [ ] usage endpoint (aggregated from AIUsageLog)
- [ ] admin audit
- [ ] super+ops gate
- [ ] Tests: CRUD, DPA gate, test-connection, usage
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_create_provider, test_dpa_required_for_ocr, test_connection_ok
## 13. Acceptance criteria
- [ ] Provider CRUD + DPA constraint + test-connection; audited; tests + lint pass.
## 14. Self-review
- [ ] API key encrypted; DPA enforced; audit present
### Deviations from spec
### Files touched (actual)
## 15. Notes
- DPA rule: any non-BD OCR provider (based on endpoint domain) requires a dpa_reference. Enforce at serializer validation.
