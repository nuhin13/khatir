---
id: T-006
epic: EPIC-13
title: Kill-switch panel page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Kill-switch panel page (Next.js)

## 1. Feature goal
The emergency kill-switch panel — 5 named switches, each requiring MFA re-entry + reason + optional lawyer reference. Visually distinct and friction-heavy by design.

## 2. Business logic
Per admin spec kill-switch UI. Each switch shows: name, description, current state, last event date/actor. Toggle → MFA dialog (re-enter 6-digit code) + reason textarea + optional lawyer reference → confirm. Red warning banner if any switch is OFF. Super only.

## 3. What this task DOES
- /killswitch page; 5 switch rows; MFA re-confirm dialog; reason + lawyer ref; event log per switch; red warning banner. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/killswitch/page.tsx; components/admin/killswitch_dialog.tsx; test
### Update
- sidebar "Kill-switch" → /killswitch

## 6–10.
No DB; consumes killswitch endpoints; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §Kill-Switch + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/killswitch`
- 5 switch rows + MFA dialog + warning banner when any is OFF
- States: all-on / any-off (warning)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] 5 named switches with state + last event
- [x] MFA re-confirm dialog (6-digit TOTP)
- [x] reason textarea + optional lawyer reference
- [x] red warning banner if any switch OFF
- [x] super-only route guard
- [x] event log section per switch
- [x] test: renders; MFA dialog opens; confirm fires endpoint
- [x] tsc pass

## 12. Test plan
### Automated
- killswitch_page renders; toggle opens MFA dialog; confirm calls endpoint
### Manual QA
1. Toggle a switch → MFA dialog → enter code + reason → confirmed → switch OFF → red banner appears.

## 13. Acceptance criteria
- [x] Kill-switch panel with MFA friction; warning banner; event log; super only; tests pass.
## 14. Self-review
- [x] MFA required; reason required; intentionally friction-heavy
### Deviations from spec
- Route is `/kill-switch` (existing scaffold + sidebar) rather than `/killswitch`; the
  page lives at `app/(dashboard)/kill-switch/page.tsx` so the already-wired nav link is not
  orphaned. Component files use `killswitch_panel.tsx` / `killswitch_dialog.tsx`.
- Nav gate changed compliance → super-only: the backend kill-switch endpoints (T-003) are
  `IsSuperAdmin`, so the spec §2.1 compliance assignment is not what is actually enforced;
  the nav + server page mirror the real backend gate to avoid an access-denied dead link.
- "Event log per switch / last event" is sourced from the switch's `updated_at`/`updated_by`
  (FeatureFlagSerializer, T-002) — the committed T-003 `GET /killswitches` returns only the
  flag rows; there is no per-switch KillSwitchEvent list endpoint, so the panel surfaces the
  most-recent-change line the API does expose.
- MFA dialog enforces a 6-digit numeric code and a ≥20-char reason client-side (spec §4.4.2);
  the backend re-verifies the TOTP and rejects a bad code with 403 (surfaced inline).
### Files touched (actual)
- `apps/admin/src/lib/api/killswitch.ts` (add — data layer)
- `apps/admin/src/components/admin/killswitch_dialog.tsx` (add — MFA + reason + lawyer ref)
- `apps/admin/src/components/admin/killswitch_panel.tsx` (add — switch list + red banner)
- `apps/admin/src/app/(dashboard)/kill-switch/page.tsx` (update — super-only guard + panel)
- `apps/admin/src/app/(dashboard)/_nav.ts` (update — Kill-switch live, super-only)
- `apps/admin/src/test/killswitch.test.tsx` (add)
- `apps/admin/src/test/sidebar.test.tsx` (update — Kill-switch now a live page)
## 15. Notes
- This is a safety-critical UI. Make it visually scary when switches are off — red banner, warning text.
