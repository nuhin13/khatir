---
id: T-003
epic: EPIC-13
title: Kill-switch endpoints (MFA re-confirm)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-003]
blocks: [T-006]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Kill-switch endpoints (MFA re-confirm)

## 1. Feature goal
Toggle the 5 named kill-switches — each requiring MFA re-confirmation, a reason, and an optional lawyer reference. Instantly propagates.

## 2. Business logic
POST /admin/api/killswitches/{key}/toggle: validate MFA TOTP code (re-confirm even within an active session); require reason; record KillSwitchEvent; disable the associated FeatureFlag (or a system config key). Instant cache bust. Super only.

## 3. What this task DOES
- Kill-switch toggle endpoint (MFA + reason + event); instant propagation; super only; tests.

## 5. Files & changes
### Add
- featureflags/killswitch_views.py; tests/test_killswitch.py
### Update
- urls

## 6. Database changes
Writes KillSwitchEvent; updates FeatureFlag or SystemConfig.
## 7. API changes
| GET | /admin/api/killswitches | super | 200 |
| POST | /admin/api/killswitches/{key}/toggle | super | 200 |

## 8–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] toggle: validate TOTP re-confirm
- [ ] require reason (and optional lawyer_reference)
- [ ] record KillSwitchEvent (immutable)
- [ ] disable FeatureFlag + cache bust
- [ ] super only
- [ ] Tests: toggle with valid MFA, wrong MFA blocked, no reason blocked, super only
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_killswitch_requires_mfa, test_wrong_mfa_blocked, test_event_created, test_super_only
## 13. Acceptance criteria
- [ ] Kill-switch requires MFA+reason; event recorded; propagates; super only; tests + lint pass.
## 14. Self-review
- [ ] MFA re-confirm enforced; immutable event; instant propagation
### Deviations from spec
### Files touched (actual)
## 15. Notes
- MFA re-confirm: even if the admin just logged in, require a fresh TOTP code for any kill-switch toggle. This is intentional friction.
