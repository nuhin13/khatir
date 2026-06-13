---
id: T-005
epic: EPIC-08
title: Maintenance web form page (token)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-004]
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

# T-005 · Maintenance web form page (token)

## 1. Feature goal
A no-install web page where a tenant reports a maintenance issue (category, description, photo) for their unit.

## 2. Business logic
`GET /m/{token}` renders the form (webMaint design); `POST /m/{token}` creates a MaintenanceRequest. Photo via encrypted storage. Rate-limited. Bilingual.

## 3. What this task DOES
- Django view + template (webMaint); submit handler → MaintenanceRequest; rate-limit; tests.

## 5. Files & changes
### Add
- maintenance/web_views.py, templates/maintenance/web_maint.html; tests/test_web_maint.py
### Update
- urls (/m/<token>)

## 6. Database changes
Writes MaintenanceRequest.
## 7. API changes
Public GET/POST /m/{token}.
## 8. UI changes
- **Design source:** screen `webMaint` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('webMaint')`)
- Surface: web-link 🌐 (Django template)
- Routes: `/m/{token}` (GET form, POST submit)
- Translate maintenance form; Notun Din palette CSS
- States: form, submitted success, invalid/expired token
- i18n: bn + en

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] GET form per webMaint design
- [ ] POST → MaintenanceRequest (+ photo encrypted)
- [ ] rate-limit; invalid/expired handling
- [ ] bn + en
- [ ] Tests: render, submit, expired
- [ ] ruff clean

## 12. Test plan
### Automated
- test_form_renders, test_submit_creates_request, test_expired
### Manual QA
1. Open maintenance link → submit → appears in landlord queue.

## 13. Acceptance criteria
- [ ] Token-scoped maintenance web form per design; submit creates request.
- [ ] **Screen `webMaint` built** (ledger row).
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Token-scoped; photo encrypted; rate-limited
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Server-rendered (not Flutter). Reuse encrypted storage (EPIC-04 T-003) for the photo.
