---
id: T-001
epic: EPIC-01
title: Seed auth SystemConfig keys
layer: backend
size: XS
status: done
preferred_agent: codex
depends_on: [EPIC-00.T-005]
blocks: [T-003]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-02
executed_by: claude-code
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Seed auth SystemConfig keys

## 1. Feature goal
Seed the admin-tunable authentication config values into `SystemConfig` so OTP behavior is configurable from day one, not hardcoded.

## 2. Business logic
Per `03_env_and_config.md`, business values live in DB (Layer 3). These keys drive OTP length, lifetime, attempt cap, resend cooldown, primary channel, and whether onboarding is skippable. The `core.config.get_config()` accessor (from EPIC-00.T-005) reads them.

## 3. What this task DOES
- A data migration (or idempotent seed command) inserting these `SystemConfig` rows with defaults + descriptions:
  - `otp_length` (int, 6)
  - `otp_ttl_seconds` (int, 300)
  - `otp_max_attempts` (int, 5)
  - `otp_resend_cooldown_seconds` (int, 60)
  - `auth_primary_channel` (text, `whatsapp`)
  - `intro_slide_skip_allowed` (bool, true)
- Ensure `intro_slide_skip_allowed` is exposed via `GET /api/v1/config/public`.

## 4. What this task does NOT do
- Does not implement OTP logic (T-003) or read these in the app yet.

## 5. Files & changes
### Add
- `apps/api/khatir/core/migrations/XXXX_seed_auth_config.py` (data migration) OR `core/management/commands/seed_auth_config.py`
- test for the public-config exposure
### Update
- the `/api/v1/config/public` view to include `intro_slide_skip_allowed`
### Delete
- none

## 6. Database changes
- Inserts rows into existing `SystemConfig` table. Reversible (migration removes the seeded keys on reverse).

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | /api/v1/config/public | none | — | adds `config.intro_slide_skip_allowed` | 200 |

## 8. UI changes
No UI changes (consumed later by onboarding).

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] Data migration / seed command inserts the 6 keys with types + descriptions
- [ ] Idempotent (re-running doesn't duplicate)
- [ ] Reversible (reverse removes the keys)
- [ ] `intro_slide_skip_allowed` surfaced in /config/public
- [ ] Test: public config returns the key
- [ ] `get_config('otp_length')` returns typed int

## 12. Test plan
### Automated
- test_seed → all 6 keys present with correct types/defaults
- test_public_config → response includes intro_slide_skip_allowed
### Manual QA
1. `make migrate` → keys present in DB.

## 13. Acceptance criteria
- [ ] 6 keys seeded with correct types + defaults.
- [ ] Public config exposes the skip flag.
- [ ] Reversible + idempotent.

## 14. Self-review
- [ ] Values match the epic's config list
- [ ] Reversible + idempotent
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Money type not used here; all int/text/bool.
- Keep descriptions human-readable — they show in the admin SystemConfig editor later.
