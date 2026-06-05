---
id: T-006
epic: EPIC-12
title: Tier impact preview widget
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Tier impact preview widget

## 1. Feature goal
A reusable modal/panel showing the impact of a proposed tier change before it's applied.

## 2. Business logic
Shows: subscribers affected (count), estimated monthly revenue delta (before/after), and a warning if the change would disable NID verification for existing subscribers. Used by T-005 pricing editor and potentially T-008 manual upgrade.

## 3. What this task DOES
- ImpactPreviewModal component; calls preview endpoint; displays counts + delta + warnings. Tests.

## 5. Files & changes
### Add
- components/admin/impact_preview_modal.tsx; test

## 6–10.
No DB; admin 🟣; no external; no flags.

## 8. UI changes
- Surface: admin · **Lane:** 🟣 admin
- Modal: subscriber count, revenue delta (+ or -), NID verification warning
- States: loading / data / warning

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] subscriber count + revenue delta
- [x] NID verification warning (if losing includes_verification)
- [x] loading + data states
- [x] reusable (not pricing-page-specific)
- [x] test: renders counts + delta + warning
- [x] tsc pass

## 12. Test plan
### Automated
- impact_preview renders subscriber count + delta + warning
## 13. Acceptance criteria
- [x] Impact preview widget; warning on NID loss; tests pass.
## 14. Self-review
- [x] Warning condition correct; reusable
### Deviations from spec
- Component takes a `TierImpact` payload as a prop (presentational) rather than fetching the preview endpoint itself, so both T-005 (pricing editor) and T-008 (manual upgrade) can reuse it after calling the endpoint. Revenue delta + NID-loss warning are exported as pure helpers (`revenueDelta`, `losesVerification`) for direct reuse/testing.
### Files touched (actual)
- apps/admin/src/components/admin/impact_preview_modal.tsx (add)
- apps/admin/src/test/impact-preview.test.tsx (add)
## 15. Notes
- Revenue delta = (new_price - old_price) × subscriber_count (monthly).
