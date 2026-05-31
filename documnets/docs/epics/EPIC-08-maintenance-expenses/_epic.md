# EPIC-08 · Maintenance & Expense Tracker

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-06
**Tasks:** 12 · **External services:** none

---

## Business goal
Tenants report repairs; landlords resolve them with a cost that becomes an expense; landlords also log expenses directly. Everything rolls into the dashboard and tax-time reporting.

## User-visible outcome
A tenant (via app later, or via the web-link maintenance form now) reports a problem with a category, description, and photo. The landlord sees a maintenance queue, resolves an item with a cost (auto-creating an expense), and can also log expenses directly. Expenses list per building/unit with CSV export.

## Scope
**In scope**
- MaintenanceRequest model + landlord queue + resolve-with-cost.
- Expense model + manual expense entry; auto-expense from resolved maintenance.
- Expense list per building/unit + CSV export.
- Tenant maintenance submission via the web-link (`webMaint`, 🌐) — no app needed (in-app tenant version is EPIC-19).
- Screens `expenses`, `addExpense` (🟢 landlord).

**Out of scope**
- Dashboard expense charts (EPIC-09 consumes this data).
- In-app tenant maintenance (EPIC-19) — web-link form covers MVP.

## Dependencies
- **Prerequisite:** EPIC-06 (unit/lease context).
- **External:** none (web-link reuses token + storage from EPIC-07/04).
- **Design:** `expenses`, `addExpense` (🟢), `webMaint` (🌐). See `07_design_map.md`.

## Data-model changes
- New `maintenance` app: `MaintenanceRequest` + `Expense` per `06_database_schema.md` Domain 6.
- `MaintenanceCategory`, `MaintenanceStatus`, `ExpenseCategory`, `ExpenseSource` enums.
- Indexes: `Expense(unit_id, date)`.

## API surface
- `GET/POST /api/v1/maintenance`, `GET /{id}`, `POST /{id}/resolve`
- `GET/POST /api/v1/expenses`, `GET/PATCH/DELETE /{id}`, `GET /api/v1/expenses/export` (CSV)
- **Public (token):** `GET /m/{token}` (maintenance web form), `POST /m/{token}` (submit)

## UI screens (from ledger)
- `expenses` → `/expenses` (🟢) — **T-008**
- `addExpense` → `/expenses/add` (🟢) — **T-009**
- `webMaint` → `/m/:token` (🌐 Django template) — **T-005**

## Feature flags introduced
None.

## Admin-portal config keys
- `expense_categories` (json), `maintenance_categories` (json) — admin-extensible.

## Test strategy
- Backend: maintenance create/resolve→auto-expense; manual expense; CSV export; web-link maintenance submit (token); for_user; audit.
- Web: maintenance form renders + submits (token-scoped).
- Mobile: maintenance queue + resolve; expense list + add; states.

## Acceptance criteria (epic-level)
- [ ] Tenant submits maintenance via web-link (token); landlord queue shows it.
- [ ] Resolve-with-cost auto-creates an Expense (source=request).
- [ ] Manual expense entry (source=manual).
- [ ] Expense list per building/unit + CSV export.
- [ ] for_user + audit.
- [ ] **Screen coverage:** `expenses`, `addExpense`, `webMaint` built per design.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Maintenance + Expense models, enums, migration | backend | M | EPIC-03.T-001 | — |
| T-002 | Maintenance CRUD + resolve→auto-expense | backend | M | T-001, EPIC-03.T-002 | — |
| T-003 | Expense CRUD + CSV export | backend | M | T-001 | — |
| T-004 | Maintenance web-link token (reuse pattern) | backend | S | EPIC-07.T-002 | — |
| T-005 | Maintenance web form page (token) | backend(web) | M | T-004 | `webMaint` 🌐 |
| T-006 | Seed expense/maintenance categories config | backend | XS | EPIC-00.T-005 | — |
| T-007 | Flutter maintenance+expense data layer | mobile | M | T-002, T-003 | — |
| T-008 | Flutter expenses list screen | mobile | M | T-007 | `expenses` |
| T-009 | Flutter add-expense screen | mobile | M | T-007 | `addExpense` |
| T-010 | Flutter maintenance queue + resolve | mobile | M | T-007 | (maintenance) |
| T-011 | Maintenance entry on unit detail | mobile | S | T-007, EPIC-03.T-013 | — |
| T-012 | Expense summary hook for dashboard | backend | XS | T-003 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Auto-expense double-counting | Resolve creates exactly one expense (source=request) idempotently |
| CSV export of large data | Stream/paginate; scoped to owner |
| Web maintenance abuse | Token-scoped + rate-limited (reuse EPIC-07 token pattern) |
