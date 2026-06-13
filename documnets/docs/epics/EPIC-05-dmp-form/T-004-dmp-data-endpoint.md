---
id: T-004
epic: EPIC-05
title: DMP form data endpoint (preview)
layer: backend
size: S
status: done
preferred_agent: codex
depends_on: [T-002]
blocks: [T-007, T-009]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-004 · DMP form data endpoint (preview)

## 1. Feature goal
`GET /tenants/{id}/dmpform` returns the assembled DMP data for the preview screen (masked NID for display; full NID only in the PDF, server-side).

## 2. Business logic
Returns the assembled fields but with NID masked for the client preview. Scoped to owner. The actual full-NID PDF generation stays server-side (T-005).

## 3. What this task DOES
- Endpoint returning assembled data (masked NID). Permission + scoping. Tests.

## 5. Files & changes
### Add
- dmpforms/views.py, serializers, urls, tests/test_dmp_data.py
### Update
- config/urls.py

## 6. Database changes
None.
## 7. API changes
| GET | /api/v1/tenants/{id}/dmpform | owner | 200 |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] endpoint returns assembled data (NID masked)
- [ ] owner-scoped
- [ ] Tests: data present, masked, cross-user 404
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_dmp_data_masked, test_scoped
### Manual QA
1. GET preview data for a tenant.

## 13. Acceptance criteria
- [ ] Preview data endpoint (masked) scoped; tests + lint pass.

## 14. Self-review
- [ ] NID masked in preview; full NID never sent to client
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Preview shows masked NID; the full value appears only in the generated PDF (server-side). Don't leak full NID to the client.
