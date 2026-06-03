---
id: T-001
epic: EPIC-02
title: Profile endpoints (get/update role, name, language)
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [EPIC-01.T-006]
blocks: [T-003]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Profile endpoints (get/update role, name, language)

## 1. Feature goal
Expose endpoints to read and update the current user's profile — name, language, and role — so the role chooser and More menu can persist changes.

## 2. Business logic
- A user updates only their own profile (row-level: the authenticated user).
- `role` must be one of `landlord|manager|tenant` here (caretaker/admin are not self-selectable). `language` ∈ `bn|en`.
- Changing role is allowed (e.g. via More → switch role) but is audited (`tenant.update`-style → use `profile.update` action).
- Logic in `accounts/services.py`; view thin.

## 3. What this task DOES
- `GET /api/v1/profile` → current user (id, phone, name, role, language).
- `PATCH /api/v1/profile` → update name/language/role (partial).
- Serializer with validation (role restricted to self-selectable set; language enum).
- Audit on profile update.
- Tests: get; update each field; invalid role/language rejected; can't update another user.

## 4. What this task does NOT do
- No UI (mobile T-003/T-007).
- Does not change auth/JWT issuance (role already in token from EPIC-01; see notes on refresh).

## 5. Files & changes
### Add
- `accounts/tests/test_profile.py`
### Update
- `accounts/serializers.py` — ProfileSerializer (read) + ProfileUpdateSerializer
- `accounts/services.py` — update_profile(user, **fields) with audit
- `accounts/views.py` + `urls.py` — /profile (GET, PATCH)
### Delete
- none

## 6. Database changes
No schema change (uses existing User fields). Writes an AuditEntry on update.

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | /api/v1/profile | Bearer | — | {id, phone, name, role, language} | 200 |
| PATCH | /api/v1/profile | Bearer | {name?, language?, role?} | updated profile | 200 |

## 8. UI changes
No UI changes.

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] ProfileSerializer + ProfileUpdateSerializer (role restricted to landlord/manager/tenant; language bn/en)
- [x] update_profile service with audit (action `profile.update`)
- [x] GET + PATCH /api/v1/profile (self only)
- [x] Tests: get, update name/language/role, invalid value rejected, cross-user blocked
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_get_profile
- test_update_name / language / role
- test_invalid_role_rejected / invalid_language_rejected
- test_cannot_update_other_user
### Manual QA
1. PATCH role landlord→manager; GET reflects it.

## 13. Acceptance criteria
- [x] Profile read + partial update work for the authenticated user only.
- [x] Role limited to self-selectable set; language validated.
- [x] Update audited.
- [x] Tests + lint pass.

## 14. Self-review
- [x] Self-only (no cross-user writes)
- [x] Role restricted; audited
### Deviations from spec
- `/profile` mounted via a new `accounts/profile_urls.py` at `/api/v1/` (not the
  `/auth/` namespace) since it is a top-level resource. Route name `profile:profile`.
- `update_profile` is a no-op (no save, no audit) when a PATCH sets fields to
  their existing values, so audit rows only record real changes.
### Files touched (actual)
- `accounts/serializers.py`, `accounts/services.py`, `accounts/views.py`
- `accounts/profile_urls.py` (new), `config/urls.py`
- `accounts/tests/test_profile.py` (new)

## 15. Notes for the implementing agent
- Role is also embedded in the JWT (EPIC-01 T-006). After a role change, the client should re-fetch `/auth/me` or refresh the token so its cached role matches DB. The DB is the source of truth — document this in §15 of the client task (T-003).
- `profile.update` audit should record which fields changed (before/after for role especially).
