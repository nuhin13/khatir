---
id: T-003
epic: EPIC-21
title: Consent-gated visibility service
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [T-001, EPIC-16.T-001]
blocks: [T-009, T-010]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Consent-gated visibility service

## 1. Feature goal
The single service that decides whether a given review is visible to a given viewer — defaulting to private, allowing the reviewer↔reviewee pair (post double-blind), and anything beyond only with a logged ConsentRecord.

## 2. Business logic
can_view_review(review, viewer) → bool. Rules: viewer is the reviewee AND double-blind satisfied → yes; viewer is the reviewer → yes (their own); any other viewer → only if a valid ConsentRecord from the reviewee authorizes it. Default deny. All consent-based reveals are logged.

## 3. What this task DOES
- Visibility service + consent integration; exhaustive tests of the rule matrix.

## 5. Files & changes
### Add
- reviews/visibility.py; tests/test_visibility.py

## 6–10.
Reads Review + ConsentRecord. No external. No flags.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] can_view_review rule matrix (reviewee+blind, reviewer, consented, else deny)
- [x] default deny
- [x] consent reveals logged
- [x] exhaustive tests of the matrix
- [x] ruff clean (mypy not in this worktree's DoD gate)

## 12. Test plan
### Automated
- test_reviewee_sees_after_blind, test_reviewer_sees_own, test_third_party_needs_consent, test_default_deny
## 13. Acceptance criteria
- [x] Visibility service with default-deny + consent gating; tests + lint pass.
## 14. Self-review
- [x] Default deny; no path to non-consented third-party access
### Deviations from spec
- mypy not in this worktree's DoD gate; ran `ruff check` + `makemigrations --check` + full pytest.
- A third-party consent reveal is gated on a *valid* `ConsentRecord` granted by
  the **reviewee** (not revoked, not expired). Consent from any other subject
  (incl. the reviewer) never authorises disclosure.
### Files touched (actual)
- Add: khatir/reviews/visibility.py, khatir/reviews/tests/test_visibility.py
## 15. Notes
- This is the gatekeeper used by every read path. If it's not allowed here, it's not visible anywhere.
