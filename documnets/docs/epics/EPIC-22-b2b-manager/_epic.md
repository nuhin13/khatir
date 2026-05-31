# EPIC-22 · B2B Manager (Multi-Owner Management)

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-03, EPIC-02
**Tasks:** 12 · **External services:** none

---

## Business goal
Support property-management companies: a manager links to multiple owners, manages their portfolios on their behalf, runs a team, and produces per-owner reports — unlocking the B2B segment (the highest-value customers).

## User-visible outcome
A manager logs in (manager role), sees a consolidated home across all linked owners (`mgrHome`), links a new owner (`mgrAddOwner`), manages team members (`mgrTeam`), and generates per-owner reports (`mgrReport`). All the landlord features work, scoped to whichever owner's portfolio they're acting on.

## Scope
**In:** Manager↔owner linking (the ManagerOwnerLink referenced since EPIC-01) with owner consent. Consolidated manager home across owners. Team management (sub-managers/staff). Per-owner reporting. The 4 manager screens. Manager-scoped access to all landlord features (the `for_user` manager branch built in EPIC-03 T-002 now fully exercised).
**Out:** Owner-side approval UI beyond consent (kept simple). Payroll/HR for the team.

## Dependencies
EPIC-02 (manager role shell), EPIC-03 (for_user manager branch + portfolio), EPIC-01 (ManagerOwnerLink model). Consumes most landlord epics' data, scoped by owner.

## Data-model changes
- `ManagerOwnerLink` (created in EPIC-01 T-002): formalize with status (pending/active/revoked), consent, permissions scope.
- `ManagerTeamMember`: manager FK, member User FK, role (staff/sub_manager), permissions.

## API surface
- `POST /api/v1/manager/owners` — request link to an owner (consent flow).
- `GET /api/v1/manager/owners` — linked owners + portfolios.
- `GET /api/v1/manager/dashboard` — consolidated across owners.
- `POST/GET /api/v1/manager/team` — team management.
- `GET /api/v1/manager/owners/{id}/report` — per-owner report (PDF).

## UI screens (from ledger)
- `mgrHome` → `/manager/home` (🟢) — **T-006**
- `mgrAddOwner` → `/manager/add-owner` (🟢) — **T-007**
- `mgrTeam` → `/manager/team` (🟢) — **T-008**
- `mgrReport` → `/manager/report` (🟢) — **T-009**

## Feature flags introduced
- `b2b_manager_enabled` (default on).

## Acceptance criteria (epic-level)
- [ ] Manager links to owners (with owner consent) and sees their portfolios.
- [ ] Consolidated manager home aggregates across all linked owners.
- [ ] Team management (add staff/sub-managers with permissions).
- [ ] Per-owner report (PDF, reuse EPIC-05).
- [ ] All landlord features work manager-scoped (for_user manager branch).
- [ ] **Screen coverage:** mgrHome, mgrAddOwner, mgrTeam, mgrReport built.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Formalize ManagerOwnerLink (consent + status + scope) | backend | M | EPIC-01.T-002 | — |
| T-002 | ManagerTeamMember model + permissions | backend | S | T-001 | — |
| T-003 | Manager owner-link endpoints (request + consent) | backend | M | T-001, EPIC-15.T-002 | — |
| T-004 | Manager consolidated dashboard endpoint | backend | M | T-001, EPIC-09.T-001 | — |
| T-005 | Per-owner report endpoint (PDF) | backend | M | T-001, EPIC-05.T-003 | — |
| T-006 | Manager home screen | mobile | M | EPIC-02.T-004, T-004 | `mgrHome` |
| T-007 | Manager add-owner screen | mobile | M | T-003 | `mgrAddOwner` |
| T-008 | Manager team screen | mobile | M | T-002 | `mgrTeam` |
| T-009 | Manager report screen | mobile | M | T-005 | `mgrReport` |
| T-010 | Manager data layer (mobile) | mobile | M | T-003, T-004, T-005 | — |
| T-011 | Manager shell wiring (fill EPIC-02 placeholders) | mobile | S | T-006, EPIC-02.T-004 | — |
| T-012 | Manager scoping + team permission test | cross-cutting | S | T-001, T-002 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Manager accessing an owner's data without consent | T-001 link requires owner consent (active status); for_user manager branch only returns active-linked owners |
| Team member privilege escalation | T-002 explicit permission scope per member; T-012 tests it |
| Cross-owner data bleed in consolidated views | T-012 asserts each owner's data stays attributed; aggregation respects links |
