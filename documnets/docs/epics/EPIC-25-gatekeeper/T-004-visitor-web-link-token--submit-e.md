---
id: T-004
epic: EPIC-25
title: Visitor web-link token + submit endpoint
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-07.T-002, T-001]
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

# T-004 · Visitor web-link token + submit endpoint

## 1. Feature goal
Building-scoped visitor token (reuse EPIC-07 signing). POST /v/{token} creates a VisitorEntry (pending) for that building. Photo via encrypted storage. Rate-limited.

## 2. Business logic
Building-scoped visitor token (reuse EPIC-07 signing). POST /v/{token} creates a VisitorEntry (pending) for that building. Photo via encrypted storage. Rate-limited.

## 3. What this task DOES
See feature goal.

## 5. Files & changes
### Add/Update
- khatir/gatekeeper/... ; tests.

## 6–10.
DB: as described. Caretaker-scoped to assigned buildings. Audited. No external. Flag gatekeeper_enabled.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal — `tokens.py` (building-scoped signed token, reuses EPIC-07 pattern) + `web_views.submit_visitor` (`POST /v/<token>/submit`) + `web_urls.py` route
- [x] Caretaker scope (assigned buildings only) where applicable — N/A here: this is the *anonymous, no-login* visitor sign-in; the token alone scopes the write to one building. Caretaker-scoped reads/reviews are T-002/T-003.
- [x] Audit on writes — `services.log_visitor_entry` writes `visitor.log` (actor=None, anonymous/system) on every entry
- [x] Tests: happy + scoping — `tests/test_tokens.py` (round-trip, building-scoped, expired, tampered, garbage, deleted) + `tests/test_web_visitor.py` (create-pending, audit, encrypted photo, empty-bounce, 404/410, GET 405, flag-off 404, rate-limit)
- [x] ruff clean (no changes detected by makemigrations)

## 12. Test plan
### Automated
- Core tests + scoping
## 13. Acceptance criteria
- [x] Feature works per goal; scoped; audited; tests + lint pass.
## 14. Self-review
- [x] Building-scoped token (one token = one building); photo stored encrypted at rest (storage `visitor` kind → opaque key → `set_photo_ref` encrypts the pointer on the row); conventions followed (no-trailing-slash path, token salt namespacing, cache rate-limit primitive, `gatekeeper_enabled` flag gate).
### Deviations from spec
- Token TTL default is 30 days (`visitor_link_token_ttl_hours`), longer than the rent/maintenance 72h, because a gate sign-in link is a reusable capability posted at the gate, not a one-shot mailed link (still tunable via config, seeded by T-012).
- The submit endpoint lives in `web_views.py` / `web_urls.py` (`POST /v/<token>/submit`, rooted outside `/api/v1/`), mirroring the rent/maintenance public web flows. The matching `GET /v/<token>` sign-in *page* + bilingual templates are owned by T-005; on token/flag errors this task returns bare 404/410/429 responses that T-005 swaps for the templated error page (same `gatekeeper_web` namespace). Success redirects (PRG) to `/v/<token>?submitted=1`.
- Added a `visitor` namespace to `core.storage._KINDS` for visitor photos (kept separate from `proof`/`nid`/`pdf` by sensitivity/lifecycle).
- No DB migration: the token is stateless and `VisitorEntry` already exists (T-001); `makemigrations --check` is clean.
### Files touched (actual)
- apps/api/khatir/gatekeeper/{tokens,web_views,web_urls}.py (new)
- apps/api/khatir/gatekeeper/services.py (add `log_visitor_entry`)
- apps/api/khatir/gatekeeper/tests/{test_tokens,test_web_visitor}.py (new)
- apps/api/khatir/core/storage.py (add `visitor` kind)
- apps/api/config/urls.py (mount `gatekeeper.web_urls`)
## 15. Notes
Building-scoped visitor token (reuse EPIC-07 signing). POST /v/{token} creates a VisitorEntry (pending) for that building. Photo via encrypted storage. Rate-limited.
