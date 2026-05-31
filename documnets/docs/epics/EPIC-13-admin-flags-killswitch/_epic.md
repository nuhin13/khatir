# EPIC-13 · Admin — Feature Flags & Kill-Switch

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-11
**Tasks:** 8 · **External services:** none

---

## Business goal
Toggle features on/off without deploys, and provide the emergency kill-switch panel for legally-sensitive features (reputation, reviews, free-text) — the legal safety valve required before any of those features can ever ship.

## Scope
**In:** FeatureFlag CRUD + toggle console; /config/public serves flags to clients; clients hide/show features within <60s of toggle. Kill-switch panel (warnings, reviews, history-flags, free-text, master) with MFA re-confirm + reason + audit. Toggling must propagate <60s.
**Out:** The features themselves — kill-switch exists before the features so it can block them from day one.

## Dependencies
EPIC-11 (admin shell). Mobile side: EPIC-04 T-006 already references a flag for voice; this wires the real flag system.

## Data-model changes
- `FeatureFlag`: key, description, scope (global/role/user), enabled, value_json, updated_by, updated_at.
- `KillSwitchEvent`: switch_key, action (enabled/disabled), reason, admin_user, lawyer_reference, created_at.

## API surface
- `GET/POST /admin/api/flags` (CRUD), `PATCH /admin/api/flags/{key}/toggle`.
- `GET /admin/api/killswitches`, `POST /admin/api/killswitches/{key}/toggle` (MFA re-confirm).
- `/config/public` serves all enabled flags to clients.

## Acceptance criteria
- [ ] Flags toggled → /config/public reflects <60s → mobile/admin hides/shows features.
- [ ] Kill-switch requires MFA re-confirm + reason + audit; no kill-switch toggle without these.
- [ ] 5 named kill-switches exist: warnings, reviews, history_flags, free_text, master.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | FeatureFlag + KillSwitchEvent models | backend | S | EPIC-00.T-005 |
| T-002 | Flag CRUD + toggle + /config/public integration | backend | M | T-001 |
| T-003 | Kill-switch endpoints (MFA re-confirm) | backend | M | T-001, EPIC-11.T-003 |
| T-004 | Seed 5 named kill-switches + default flags | backend | S | T-001 |
| T-005 | Flags console page (Next.js) | admin | M | T-002, EPIC-11.T-008 |
| T-006 | Kill-switch panel page (Next.js) | admin | M | T-003 |
| T-007 | Mobile flag reader (wire EPIC-04 voice flag) | mobile | S | T-002 |
| T-008 | Flag propagation test (<60s) | cross-cutting | S | T-002 |
