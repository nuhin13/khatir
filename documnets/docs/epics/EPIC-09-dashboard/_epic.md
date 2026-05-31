# EPIC-09 · Dashboard & Visualizations

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-07, EPIC-08
**Tasks:** 10 · **External services:** none

---

## Business goal
Give landlords an at-a-glance financial picture: income collected, collection rate, occupancy, expense breakdown, and late payers — the "open it daily" screen that drives retention.

## User-visible outcome
The landlord opens the Charts tab (bottom nav) and sees: a 6-month collection bar chart, an occupancy donut, an income-vs-expense summary, a top-expense-categories breakdown, and the late-payers list with quick-request actions. All numbers are live and correct.

## Scope
**In scope**
- Dashboard aggregation API (rent collected, pending, overdue, occupancy, expense totals, monthly series).
- `dashboard` screen (🟢) — the Charts tab in the landlord shell.
- Fills the chart/summary placeholders left by EPIC-03 T-009 (landlord home) and EPIC-07 T-014 (late-payers — already filled; dashboard adds charts).
- fl_chart visualizations: bar chart (6-month collection), donut (occupancy), income-vs-expense line/bar.

**Out of scope**
- Manager consolidated reports (EPIC-22).
- Tenant-side analytics.
- Export / tax reports (EPIC-16 compliance export).

## Dependencies
- **Prerequisite:** EPIC-07 (payments), EPIC-08 (expenses) — both provide the data.
- **Design:** screen `dashboard`. See `07_design_map.md`.

## Data-model changes
None — pure aggregation over existing tables.

## API surface
- `GET /api/v1/dashboard` — all metrics in one call (with optional `months` param, default 6).

## UI screens (from ledger)
- `dashboard` → `/landlord/dashboard` (🟢) — **T-006**

## Feature flags introduced
None.

## Admin-portal config keys
- `dashboard_months_default` (int, default 6).

## Test strategy
- Backend: aggregation correctness (mock a set of payments/expenses; verify the numbers); scoped to owner; performant (no N+1).
- Mobile: charts render from data; empty state; loading; fl_chart widget tests.

## Acceptance criteria (epic-level)
- [ ] Dashboard API returns correct collection rate, occupancy, income, expense totals, monthly series.
- [ ] 6-month collection bar chart, occupancy donut, income-vs-expense all render with live data.
- [ ] `dashboard` screen fills Charts tab in landlord shell (replaces placeholder).
- [ ] Empty state (no data yet) handled gracefully.
- [ ] **Screen `dashboard` built** per design; ledger row checked.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Dashboard aggregation selectors | backend | M | EPIC-07.T-001, EPIC-08.T-003 |
| T-002 | Dashboard API endpoint | backend | S | T-001 |
| T-003 | Seed dashboard config | backend | XS | EPIC-00.T-005 |
| T-004 | Flutter dashboard data layer | mobile | S | T-002 |
| T-005 | fl_chart shared chart widgets | mobile | M | EPIC-00.T-008 |
| T-006 | Dashboard screen | mobile | M | T-004, T-005 | `dashboard` |
| T-007 | Fill home screen chart placeholder (EPIC-03) | mobile | S | T-006, EPIC-03.T-009 |
| T-008 | Collection rate + occupancy summary cards | mobile | S | T-004 |
| T-009 | Income-vs-expense chart | mobile | M | T-004, T-005 |
| T-010 | Dashboard performance test | backend | S | T-001 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Aggregation N+1 | T-010 perf test; use ORM annotations |
| fl_chart rendering edge cases | Widget tests; empty/single-point states |
| Charts empty for new landlords | Friendly empty state with onboarding copy |
