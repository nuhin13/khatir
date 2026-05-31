---
id: T-002
epic: EPIC-21
title: Review submit + view endpoints (kill-switch + consent)
layer: backend
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, EPIC-13.T-002]
blocks: [T-005, T-006, T-007, T-008, T-009, T-010]
external_services: []
feature_flags: [reviews_feature]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Review submit + view endpoints (kill-switch + consent)

## 1. Feature goal
Submit a review and view reviews about oneself — kill-switch gated, relationship-scoped, consent-respecting. No public/search endpoint, by design.

## 2. Business logic
Kill-switch (`reviews_feature`) first → off = 403. Submit: only between the two parties of a real lease; one review per party per lease; audit. View: `/me/reviews` returns reviews about me, applying the reveal/consent rules (T-003). There is deliberately NO endpoint to look up reviews about another person, or any public/aggregate listing.

## 3. What this task DOES
- Submit + /me/reviews endpoints; kill-switch + relationship gate; reveal rules via T-003; audit; tests. Explicitly NO public/search route.

## 5. Files & changes
### Add
- reviews/{serializers,services,views,urls}.py; tests/test_review_api.py
### Update
- config/urls.py

## 6. Database changes
Writes Review.
## 7. API changes
| POST | /api/v1/leases/{id}/reviews | lease party + reviews_feature | 201 |
| GET | /api/v1/me/reviews | self | 200 |
| (NONE) | no public/search endpoint | — | by design |

## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
- reviews_feature (kill-switch)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] reviews_feature kill-switch gate (off → 403)
- [ ] submit: lease-party only, one per party per lease, audit
- [ ] /me/reviews applies reveal + consent rules (T-003)
- [ ] NO public/search/aggregate endpoint exists
- [ ] Tests: submit, double-blind reveal, kill-switch off, non-party blocked, no-public-route
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_submit_party_only, test_me_reviews_reveal, test_killswitch_off, test_non_party_403
### Manual QA
1. Both parties submit → each sees the other's. Kill-switch off → feature gone.

## 13. Acceptance criteria
- [ ] Submit + view, kill-switch + relationship gated, reveal rules applied, no public route; tests + lint pass.
## 14. Self-review
- [ ] No public/aggregate endpoint; kill-switch first; party-scoped
### Deviations from spec
### Files touched (actual)
## 15. Notes
- If you ever feel tempted to add a "search reviews" or "landlord reputation" endpoint — STOP. That is the illegal feature. This epic forbids it by construction.
