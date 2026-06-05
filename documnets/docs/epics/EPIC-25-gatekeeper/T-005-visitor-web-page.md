---
id: T-005
epic: EPIC-25
title: Visitor self-register web page
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-004]
blocks: []
external_services: []
feature_flags: [gatekeeper_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Visitor self-register web page

## 1. Feature goal
A no-install web page at the gate where a visitor self-registers (name, purpose, who they're visiting, optional photo) → routed to the caretaker for review.

## 2. Business logic
Per `webVisitor` design (emojiHero 👋 'Welcome, visitor', 'অতিথি তথ্য দিন', go('careReview')). GET /v/{token} renders the form; POST creates a VisitorEntry (pending). Privacy notice for the photo. Bilingual. Token-scoped to a building.

## 3. What this task DOES
- Django view + template (webVisitor); submit → VisitorEntry; privacy notice; bilingual; tests.

## 5. Files & changes
### Add
- gatekeeper/web_views.py, templates/gatekeeper/web_visitor.html; tests/test_web_visitor.py
### Update
- urls (/v/<token>)

## 6–10.
Writes VisitorEntry. Public token route. Web 🌐. Flag gatekeeper_enabled.

## 8. UI changes
- **Design source:** screen `webVisitor` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('webVisitor')`)
- Surface: web-link 🌐 (Django template)
- Routes: `/v/{token}` (GET form, POST submit)
- Translate visitor form + privacy notice; Notun Din palette CSS
- States: form / submitted / invalid token
- i18n: bn + en

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] GET form per webVisitor design — `web_views.web_visitor` (`GET /v/<token>`) renders `templates/gatekeeper/web_visitor.html` (emojiHero 👋 Welcome/অতিথি তথ্য দিন, name/mobile/flat/meet/purpose/selfie)
- [x] POST → VisitorEntry (pending) + optional photo (encrypted) — owned by T-004 (`POST /v/<token>/submit`); the form now posts to it and PRG redirects to `?submitted=1`
- [x] privacy notice for photo — bilingual auto-delete notice in the form template
- [x] rate-limit; invalid/expired handling — reuses T-004 per-token limit; invalid/expired/rate-limited/flag-off now render `web_visitor_error.html` (404/410/429)
- [x] bn + en — bn-default with `lang="en"` companion strings + `{% translate %}` throughout (shares `rent/_web_base.html` Notun Din palette)
- [x] Tests: render, submit, expired — `tests/test_web_visitor_page.py` (render, submitted-state, invalid 404, expired 410, POST-405, flag-off 404); T-004 submit tests still pass
- [x] ruff clean — `ruff check .` clean; `makemigrations --check` clean (no DB change)

## 12. Test plan
### Automated
- test_visitor_form_renders, test_submit_creates_entry, test_expired
### Manual QA
1. Open visitor link → register → appears in caretaker review queue.

## 13. Acceptance criteria
- [x] Visitor web page per design; submit creates entry (page = T-005, create = T-004 submit endpoint the form posts to).
- [x] **Screen `webVisitor` built** (server-rendered Django template, not Flutter).
- [x] Tests + lint pass.

## 14. Self-review
- [x] Token-scoped (one token = one building, T-004 `resolve_token`); photo encrypted at rest + bilingual consent notice; Notun Din palette via shared `rent/_web_base.html` CSS custom properties (no hardcoded hex/px)
### Deviations from spec
- Submit (POST → VisitorEntry + encrypted photo + rate-limit + audit) was already delivered by T-004 (`POST /v/<token>/submit`); T-005 adds only the `GET /v/<token>` page + bilingual templates and swaps T-004's bare 404/410/429 bodies for the friendly templated error page. The form posts to the existing T-004 endpoint.
- Server-rendered (Django template), not Flutter, per §15.
- No DB migration (stateless token, `VisitorEntry` already exists); `makemigrations --check` clean.
### Files touched (actual)
- apps/api/khatir/gatekeeper/web_views.py (add `web_visitor` GET view + `_flag_off_404`; templated error/rate-limit responses)
- apps/api/khatir/gatekeeper/web_urls.py (add `GET /v/<token>` → `visitor-page`)
- apps/api/templates/gatekeeper/web_visitor.html (new — form + submitted state)
- apps/api/templates/gatekeeper/web_visitor_error.html (new — invalid/expired/rate-limited)
- apps/api/khatir/gatekeeper/tests/test_web_visitor_page.py (new)
## 15. Notes
- Server-rendered (not Flutter). Reuse encrypted storage (EPIC-04 T-003) + token pattern (EPIC-07 T-002).
