---
id: T-005
epic: EPIC-07
title: Tenant web pay page (token)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-002]
blocks: [T-006]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Tenant web pay page (token)

## 1. Feature goal
The no-install web page a tenant opens from the WhatsApp link: shows what's owed + pay instructions, served by Django (token-scoped, no login).

## 2. Business logic
`GET /r/{token}` resolves the token (T-002) → renders a styled page (Khatir tokens) with amount, period, landlord, bKash/Nagad instructions, and a proof form. Invalid/expired → friendly error. Mobile-first, Bangla default.

## 3. What this task DOES
- Django view + template for /r/{token}; renders webPay design; handles invalid/expired; bilingual. Tests (valid/expired render).

## 5. Files & changes
### Add
- rent/web_views.py, templates/rent/web_pay.html, static; tests/test_web_pay.py
### Update
- urls (public /r/<token>)

## 6. Database changes
None (reads).
## 7. API changes
Public GET /r/{token} (HTML).
## 8. UI changes
- **Design source:** screen `webPay` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('webPay')`)
- Surface: web-link 🌐 (Django template, NOT Flutter)
- Route: `/r/{token}`
- Translate web pay page; use the Notun Din palette (shared tokens) in CSS
- States: valid (data), invalid/expired token (friendly error)
- i18n: bn default + en (template-level)

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] GET /r/{token} resolves token → render
- [ ] webPay template (amount, period, instructions, proof form) per design
- [ ] invalid/expired friendly page
- [ ] mobile-first, bn default + en
- [ ] Tests: valid render, expired/invalid
- [ ] ruff clean

## 12. Test plan
### Automated
- test_valid_token_renders, test_expired_shows_error
### Manual QA
1. Open a real link in a browser → page renders.

## 13. Acceptance criteria
- [ ] Token-scoped web pay page per design; invalid/expired handled.
- [ ] **Screen `webPay` built** (ledger row).
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] No login; token scopes to one request; tokens-as-CSS palette
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- This is server-rendered HTML, not Flutter. Use the Notun Din palette in CSS to match the prototype's webPay. No enumeration of other requests.
