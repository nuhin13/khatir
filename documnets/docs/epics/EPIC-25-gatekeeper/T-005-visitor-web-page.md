---
id: T-005
epic: EPIC-25
title: Visitor self-register web page
layer: backend
size: M
status: todo
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
- [ ] GET form per webVisitor design
- [ ] POST → VisitorEntry (pending) + optional photo (encrypted)
- [ ] privacy notice for photo
- [ ] rate-limit; invalid/expired handling
- [ ] bn + en
- [ ] Tests: render, submit, expired
- [ ] ruff clean

## 12. Test plan
### Automated
- test_visitor_form_renders, test_submit_creates_entry, test_expired
### Manual QA
1. Open visitor link → register → appears in caretaker review queue.

## 13. Acceptance criteria
- [ ] Visitor web page per design; submit creates entry.
- [ ] **Screen `webVisitor` built** (ledger row).
- [ ] Tests + lint pass.

## 14. Self-review
- [ ] Token-scoped; photo encrypted + consented; Notun Din palette
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Server-rendered (not Flutter). Reuse encrypted storage (EPIC-04 T-003) + token pattern (EPIC-07 T-002).
