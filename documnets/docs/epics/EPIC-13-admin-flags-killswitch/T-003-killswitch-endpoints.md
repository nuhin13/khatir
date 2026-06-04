---
id: T-003
epic: EPIC-13
title: Kill-switch endpoints (MFA re-confirm)
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-11.T-003]
blocks: [T-006]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
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
- [x] toggle: validate TOTP re-confirm
- [x] require reason (and optional lawyer_reference)
- [x] record KillSwitchEvent (immutable)
- [x] disable FeatureFlag + cache bust
- [x] super only
- [x] Tests: toggle with valid MFA, wrong MFA blocked, no reason blocked, super only
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_killswitch_requires_mfa, test_wrong_mfa_blocked, test_event_created, test_super_only
## 13. Acceptance criteria
- [x] Kill-switch requires MFA+reason; event recorded; propagates; super only; tests + lint pass.
## 14. Self-review
- [x] MFA re-confirm enforced; immutable event; instant propagation
### Deviations from spec
- Toggle uses POST (per §7 API table) flipping `enabled` in either direction; the recorded
  `KillSwitchEvent.action` is `disable` when killing a live feature and `enable` when restoring,
  so the same endpoint covers both throws (the immutable event distinguishes them).
- Kill-switches map to the 5 seeded `scope=global` FeatureFlag rows (T-004 convention:
  `enabled=True` = feature live); no separate SystemConfig key needed.
- MFA re-confirm is skipped only when `ADMIN_MFA_REQUIRED` is off AND the account has no TOTP
  secret (dev/test convenience); any account WITH a secret is always re-confirmed.
### Files touched (actual)
- `apps/api/khatir/featureflags/killswitch_views.py` (add)
- `apps/api/khatir/featureflags/tests/test_killswitch.py` (add)
- `apps/api/khatir/featureflags/services.py` (kill-switch services: keys, MFA re-confirm, toggle)
- `apps/api/khatir/featureflags/urls.py` (route `killswitches` + `killswitches/{key}/toggle`)
## 15. Notes
- MFA re-confirm: even if the admin just logged in, require a fresh TOTP code for any kill-switch toggle. This is intentional friction.
