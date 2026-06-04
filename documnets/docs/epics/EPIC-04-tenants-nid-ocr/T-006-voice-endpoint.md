---
id: T-006
epic: EPIC-04
title: Voice endpoint (audio → fields)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003, T-004]
blocks: [T-012]
external_services: [asr]
feature_flags: [voice_tenant_entry]
started_at:
completed_at: 2026-06-04
executed_by: claude
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
- [x] audio intake
- [x] ASR extract → fields
- [x] voice_tenant_entry flag gate
- [x] permission + rate-limit
- [x] audio not retained post-extraction
- [x] Tests (mocked, flag on/off)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_voice_returns_fields, test_flag_off_returns_403, test_requires_landlord
### Manual QA
1. POST audio → fields; toggle flag off → 403.

## 13. Acceptance criteria
- [x] Voice extraction works + flag-gated; tests + lint pass.

## 14. Self-review
- [x] Audio discarded post-extraction; flag respected
### Deviations from spec
- Flag check is abstracted in a small `tenants/flags.py` (`is_feature_enabled`,
  `VOICE_TENANT_ENTRY`) rather than reading the featureflags model inline.
  EPIC-13's `FeatureFlag` is already committed, so the helper resolves a
  **global** flag row when present and falls back to the §10 default (**on**)
  when unconfigured — EPIC-13 can later widen resolution (role/user scope,
  caching) without touching the view.
- Intake uses a DRF `FileField` (not a media-typed field), mirroring the OCR
  endpoint (T-005): the ASR provider, not the API, owns audio-byte interpretation.
- Rate-limit reuses the OCR throttle pattern — a shared `_PerUserScopedThrottle`
  base with a new `VoiceUserThrottle` (`tenant_voice` scope, default `30/hour`,
  env-tunable via `THROTTLE_TENANT_VOICE`); 429 → standard `rate_limited` envelope.
- Response serializer shares the `{value, confidence}` field-mapping with OCR via
  a module-level `_extracted_fields`; voice omits `photo_ref` (no stored artefact).
- Sync (not Celery) extraction, accepted for MVP per the sibling T-005 §15.
### Files touched (actual)
- apps/api/khatir/tenants/views.py — `TenantVoiceView`
- apps/api/khatir/tenants/flags.py — `is_feature_enabled` / `VOICE_TENANT_ENTRY` (new)
- apps/api/khatir/tenants/serializers.py — `VoiceRequestSerializer` / `VoiceResponseSerializer` / `_extracted_fields`
- apps/api/khatir/tenants/throttling.py — `VoiceUserThrottle` + shared base
- apps/api/khatir/tenants/urls.py — `tenants/voice` route
- apps/api/config/settings/base.py — `tenant_voice` throttle rate
- apps/api/khatir/tenants/tests/test_voice_endpoint.py — tests (new)

## 15. Notes for the implementing agent
- Flag read via featureflags app (built EPIC-13); until then read from SystemConfig/config. Keep the check abstracted so EPIC-13 wires the real flag.
