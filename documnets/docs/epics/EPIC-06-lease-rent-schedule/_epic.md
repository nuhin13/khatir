# EPIC-06 · Lease & Rent Schedule

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-04
**Tasks:** 10 · **External services:** none

---

## Business goal
Create a lease tying a unit + tenant + landlord (rent, advance, dates), and auto-generate the monthly rent schedule that later triggers rent requests. This is the engine behind recurring rent collection.

## User-visible outcome
After registering a tenant, the landlord creates a lease (rent, advance, start/end), activates it, and the system automatically lays out each month's rent (amount + due day). The unit detail now shows the active lease + tenant; upcoming/overdue rent is computed from the schedule.

## Scope
**In scope**
- Lease CRUD + status lifecycle (draft → active → ended/terminated).
- On activation, auto-generate RentSchedule rows (period, due_day, due_date, amount).
- A monthly background job (Celery Beat) to roll schedules forward and flag overdue.
- Lease + schedule surfaced on unit detail (fills the EPIC-03 placeholder).
- Lease list/detail for the landlord.

**Out of scope**
- Rent requests / payment collection (EPIC-07 — consumes the schedule).
- AI lease document generation + e-sign (EPIC-18, P1) — this is the data lease, not the legal PDF.
- Tenant-app lease view (EPIC-19).

## Dependencies
- **Prerequisite:** EPIC-04 (tenant) + EPIC-03 (unit).
- **External:** none.
- **Design:** lease screens are minimal in the prototype (the AI-lease `lease` screen is EPIC-18); the data-lease UI is built on the unit detail + a lease form. No dedicated ledger screen here beyond unit detail integration.

## Data-model changes
- New `leases` app: `Lease` + `RentSchedule` per `06_database_schema.md` Domain 4.
- `LeaseStatus`, `RentScheduleStatus` enums.
- Indexes: `Lease(landlord_id, status)`, `Lease(unit_id)`, `RentSchedule(lease_id, status)`.

## API surface
- `GET/POST /api/v1/leases`, `GET/PATCH /api/v1/leases/{id}`, `POST /api/v1/leases/{id}/activate`, `/terminate`
- `GET /api/v1/leases/{id}/schedule`
- `GET /api/v1/units/{id}/lease` (current active lease)

## UI screens
- No new ledger screen (lease integrates into `unit` detail from EPIC-03 + a lease form). `lease` screen in the prototype = AI lease (EPIC-18). 

## Feature flags introduced
None.

## Admin-portal config keys
- `default_due_day` (int, default 5), `rent_overdue_grace_days` (int, default 3).

## Test strategy
- Backend: lease CRUD + lifecycle; schedule auto-generation correctness (periods, due dates, amounts); monthly roll-forward job; overdue flagging; for_user scoping.
- Mobile: lease create form; unit detail shows active lease + schedule summary; states.

## Acceptance criteria (epic-level)
- [ ] Lease created with unit+tenant+landlord, rent, advance, dates; lifecycle works.
- [ ] Activation auto-generates the monthly RentSchedule.
- [ ] Celery Beat rolls schedules forward + flags overdue.
- [ ] Unit detail shows active lease + tenant + upcoming rent (fills EPIC-03 placeholder).
- [ ] for_user isolation; audit on lease create/activate/terminate.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Lease + RentSchedule models, enums, migration | backend | M | EPIC-04.T-001, EPIC-03.T-001 |
| T-002 | Rent-schedule generation service | backend | M | T-001 |
| T-003 | Lease CRUD + lifecycle endpoints | backend | M | T-001, EPIC-03.T-002 |
| T-004 | Schedule endpoints + unit current-lease | backend | S | T-002, T-003 |
| T-005 | Monthly roll-forward + overdue Celery task | backend | M | T-002, EPIC-00.T-006 |
| T-006 | Seed due-day/grace config | backend | XS | EPIC-00.T-005 |
| T-007 | Flutter leases data layer | mobile | M | T-003, T-004 |
| T-008 | Lease create/edit form | mobile | M | T-007 |
| T-009 | Lease section on unit detail (fill EPIC-03 placeholder) | mobile | M | T-007, EPIC-03.T-013 |
| T-010 | Lease list/detail screen | mobile | M | T-007 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Schedule generation edge cases (month-end due days, partial months) | Pure, well-tested generation function; due_day clamps to month length |
| Overdue flagging timezone bugs | UTC dates; grace from config; tested |
| Lease without tenant/unit | Enforce FKs + validation at create |
