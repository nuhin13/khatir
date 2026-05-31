---
id: T-005
epic: EPIC-08
title: Tenant maintenance web form (token)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-07.T-002]
blocks: [T-012]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Tenant maintenance web form (token)

## 1. Feature goal
A no-install web form where a tenant reports a maintenance issue (category, description, photo) via a token link.

## 2. Business logic
Reuses the EPIC-07 token pattern (per-tenant/unit maintenance token). `GET /m/{token}` renders the form; `POST /m/{token}` creates a MaintenanceRequest (photo via encrypted storage). Token-scoped, rate-limited.

## 3. What this task DOES
- Django view + template for `webMaint`; submit handler; token validation; tests.

## 5. Files & changes
### Add
- maintenance/web_views.py, templates/maintenance/web_maint.html; tests/test_web_maint.py
### Update
- urls (/m/<token>)

## 6. Database changes
Writes MaintenanceRequest.
## 7. API changes
Public GET /m/{token}, POST /m/{token}.
## 8. UI changes
- **Design source:** screen `webMaint` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('webMaint')`)
- Surface: web-link 🌐 (Django template)
- Route: `/m/{token}`
- Translate maintenance form; Notun Din palette CSS; bn default + en
- States: form, success, invalid/expired token

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] GET /m/{token} renders webMaint form
- [ ] POST creates MaintenanceRequest (photo encrypted)
- [ ] token-scoped + rate-limited
- [ ] invalid/expired page
- [ ] Tests: render, submit, expired
- [ ] ruff clean

## 12. Test plan
### Automated
- test_form_renders, test_submit_creates_request, test_expired
### Manual QA
1. Open link → submit issue with photo → appears in landlord queue.

## 13. Acceptance criteria
- [ ] Maintenance web form per design; token-scoped; creates request.
- [ ] **Screen `webMaint` built** (ledger row).
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Reuses token + encrypted storage patterns; palette CSS
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse EPIC-07 token service (generalize it for maintenance) + EPIC-04 encrypted storage. Server-rendered, not Flutter.
