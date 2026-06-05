---
id: T-008
epic: EPIC-24
title: Recipient view (web-link, factual only)
layer: backend
size: M
status: done
preferred_agent: codex
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: [history_flags_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Recipient view (web-link, factual only)

## 1. Feature goal
A token web page where the prospective landlord views the shared FACTUAL stats (no app needed). Read-only, no export, expiry-enforced. Server-rendered, Notun Din palette.

## 2. Business logic
A token web page where the prospective landlord views the shared FACTUAL stats (no app needed). Read-only, no export, expiry-enforced. Server-rendered, Notun Din palette.

## 3. What this task DOES
See feature goal. Built defensively — tenant-controlled, consent-per-share, factual-only, kill-switchable.

## 5. Files & changes
### Add/Update
- khatir/historyshare/... or features/historyshare/... ; tests.

## 6–10.
DB/web as described; backend. No external. Flag: [history_flags_feature].

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Core implementation per goal
- [x] Tenant-controlled + consent + factual-only as applicable
- [x] Tests
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- Core tests per goal
## 13. Acceptance criteria
- [x] Feature works per goal; tenant-controlled + consent-gated + factual-only; tests pass.
## 14. Self-review
- [x] Tenant initiates; consent logged; factual only; revocable
### Deviations from spec
- The recipient page is a plain Django HTML view (`GET /h/<token>`) rooted OUTSIDE
  `/api/v1/`, mirroring the existing public token-scoped web surfaces
  (`khatir.rent.web_views` / `web_urls`, `khatir.maintenance.web_views`). It reuses
  the same Notun Din palette via `templates/rent/_web_base.html` (CSS custom
  properties sourced from `packages/design-tokens`), so no prototype hex/px is
  hardcoded. There is no dedicated prototype screen key for this recipient view in
  `07_design_map.md`, so the composition follows the rent web-pay card pattern.
- Same gate as the T-003 JSON endpoint: kill-switch (`history_flags_feature`) +
  `HistoryShare.is_readable()` (active AND consent valid). A missing, revoked,
  expired, consent-withdrawn, or kill-switched share ALL render the identical
  friendly error page (HTTP 404) so lifecycle state never leaks. GET-only
  (`@require_http_methods(["GET"])` → POST/PUT/PATCH/DELETE = 405); the template has
  no form, no download/export affordance — read-only by construction.
- No model/migration changes (the page reuses the T-003 token + `factual_stats`
  snapshot) → `makemigrations --check` clean.
### Files touched (actual)
- apps/api/khatir/historyshare/web_views.py (web_history view, Bangla-numeral + error helpers)
- apps/api/khatir/historyshare/web_urls.py (/h/<token> route)
- apps/api/config/urls.py (mount historyshare.web_urls at root)
- apps/api/templates/historyshare/web_history.html (factual stats page, extends rent/_web_base)
- apps/api/templates/historyshare/web_history_error.html (friendly unavailable page)
- apps/api/khatir/historyshare/tests/test_web_history.py (10 tests)
## 15. Notes
A token web page where the prospective landlord views the shared FACTUAL stats (no app needed). Read-only, no export, expiry-enforced. Server-rendered, Notun Din palette.
