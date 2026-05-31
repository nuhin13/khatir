---
id: T-002
epic: EPIC-13
title: Flag CRUD + toggle + /config/public integration
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-005, T-007, T-008]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Flag CRUD + toggle + /config/public integration

## 1. Feature goal
CRUD + toggle for feature flags; all enabled flags served in /config/public so clients react within <60s.

## 2. Business logic
GET/POST/PATCH flags. PATCH /{key}/toggle: flips enabled, records updated_by+at, busts /config/public cache. /config/public gains a `flags` dict of key→enabled for all global flags. Super+ops.

## 3. What this task DOES
- Flag endpoints; toggle + cache bust; /config/public flags dict; tests (toggle + propagation).

## 5. Files & changes
### Add
- featureflags/{serializers,services,views,urls}.py; tests
### Update
- core (or config) /config/public view — add flags dict

## 6. Database changes
Writes FeatureFlag rows.
## 7. API changes
| GET/POST | /admin/api/flags | super/ops | 200/201 |
| PATCH | /admin/api/flags/{key}/toggle | super/ops | 200 |
| — | /config/public gains flags{} | public | — |

## 8. UI changes
No UI (T-005).
## 9–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] flag CRUD
- [ ] toggle (flip enabled + bust cache + audit)
- [ ] /config/public flags dict
- [ ] super+ops gate
- [ ] Tests: toggle, /config/public reflects
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_toggle_reflects_in_config_public
## 13. Acceptance criteria
- [ ] Flags toggle + /config/public; <60s propagation; tests + lint pass.
## 14. Self-review
- [ ] Cache key consistent; audited
### Deviations from spec
### Files touched (actual)
## 15. Notes
- /config/public flag format: {"flags": {"voice_tenant_entry": true, "dmp_enabled": true, …}}. Clients read this dict.
