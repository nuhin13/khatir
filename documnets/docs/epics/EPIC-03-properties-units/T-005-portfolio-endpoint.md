---
id: T-005
epic: EPIC-03
title: Portfolio aggregation endpoint
layer: backend
size: S
status: todo
preferred_agent: codex
depends_on: [T-003, T-004]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-005 · Portfolio aggregation endpoint

## 1. Feature goal
One endpoint returning the landlord's portfolio summary: buildings with unit counts, occupancy, and total rent — powering the portfolio list and home tiles.

## 2. Business logic
Aggregate per building: total units, occupied/vacant/maintenance counts, sum of rent. Scoped via for_user. Efficient (annotate, avoid N+1).

## 3. What this task DOES
- `GET /api/v1/portfolio` → list of buildings each with summary + a top-level totals object.
- Selector with annotations. Tests on the math + scoping.

## 5. Files & changes
### Add
- `properties/selectors.py`, `properties/tests/test_portfolio.py`
### Update
- `properties/views.py`, `urls.py`

## 6. Database changes
None (reads).

## 7. API changes
| Method | Path | Auth | Status |
|--------|------|------|--------|
| GET | /api/v1/portfolio | Bearer | 200 |

## 8. UI changes
No UI changes.

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] portfolio selector (annotated counts + rent sum)
- [ ] endpoint scoped via for_user
- [ ] totals object
- [ ] Tests: counts/occupancy/rent correct; scoped
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_portfolio_counts / occupancy / rent_sum / scoped
### Manual QA
1. With 2 buildings, verify summary numbers.

## 13. Acceptance criteria
- [ ] Accurate aggregation, scoped, performant; tests + lint pass.

## 14. Self-review
- [ ] No N+1; for_user applied
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use ORM annotations/aggregations, not Python loops, for counts.
