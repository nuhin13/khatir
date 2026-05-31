---
id: T-006
epic: EPIC-04
title: Voice endpoint (audio → fields)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-012]
external_services: [asr]
feature_flags: [voice_tenant_entry]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Voice endpoint (audio → fields)

## 1. Feature goal
`POST /tenants/voice` accepts a Bangla audio clip, transcribes + extracts tenant fields, returns editable fields.

## 2. Business logic
ASR via TenantExtractionProvider (T-004). Gated by `voice_tenant_entry` flag. Audio not retained beyond extraction (privacy) unless needed; return normalized fields only.

## 3. What this task DOES
- Endpoint (audio) → ASR extract → fields. Flag check (feature_disabled if off). Permission + rate-limit. Tests (mocked).

## 5. Files & changes
### Add
- voice view, tests/test_voice_endpoint.py
### Update
- urls

## 6. Database changes
None.
## 7. API changes
| Method | Path | Auth | Status |
| POST | /api/v1/tenants/voice | landlord/mgr | 200 (or 403 feature_disabled) |

## 8. UI changes
No UI.
## 9. External services
ASR provider.
## 10. Feature flags
- voice_tenant_entry · default on · global

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] audio intake
- [ ] ASR extract → fields
- [ ] voice_tenant_entry flag gate
- [ ] permission + rate-limit
- [ ] audio not retained post-extraction
- [ ] Tests (mocked, flag on/off)
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_voice_returns_fields, test_flag_off_returns_403, test_requires_landlord
### Manual QA
1. POST audio → fields; toggle flag off → 403.

## 13. Acceptance criteria
- [ ] Voice extraction works + flag-gated; tests + lint pass.

## 14. Self-review
- [ ] Audio discarded post-extraction; flag respected
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Flag read via featureflags app (built EPIC-13); until then read from SystemConfig/config. Keep the check abstracted so EPIC-13 wires the real flag.
