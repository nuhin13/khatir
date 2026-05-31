# EPIC-03 · Properties & Units

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-02
**Tasks:** 14 · **External services:** OpenStreetMap tiles (free, no key)

---

## Business goal

Let a landlord build their portfolio: create buildings via the 4-step wizard (name+area → address+map → units → review), auto-generate units, and manage units (rent, type, status). This is the structural data spine — tenants, leases, rent, and the DMP form all attach to a unit.

## User-visible outcome

A landlord taps "Add building," names it and picks a Dhaka area, sets the address (optionally by dropping a map pin), specifies floors × flats-per-floor with a numbering scheme to auto-generate units, reviews, and saves. They then see their portfolio (buildings → units) and can open a unit to set rent/status and later attach a tenant.

## Scope

**In scope**
- Building CRUD + the 4-step add-building wizard (matching the `addBuilding` design exactly: name+area, address+map pin, units generator, review).
- Map pin via flutter_map + OSM tiles (optional; address required).
- Unit auto-generation (floors × per-floor, letter `1A`/number `101` schemes, custom labels, removable).
- Unit CRUD; status occupied/vacant/maintenance; rent; type; amenities.
- Portfolio list (buildings with unit counts + occupancy).
- Unit detail screen.
- Row-level `for_user` scoping (landlord sees only own; manager via owner links — wired but manager UI is EPIC-22).

**Out of scope**
- Tenants/leases on a unit (EPIC-04/06) — the unit detail links to "add tenant" which EPIC-04 builds.
- Dashboard charts on the home screen (EPIC-09) — the `home` screen shell is built here with placeholders for the chart card.
- Manager multi-owner portfolio view (EPIC-22).

## Dependencies

- **Prerequisite:** EPIC-02 (role shells; the landlord shell's Home tab is filled here).
- **External:** OpenStreetMap tiles (no key, free) for the map-pin step.
- **Design:** screens `home`, `addBuilding` (4-step), `portfolio`, `unit`. See `07_design_map.md`.

## Data-model changes

- New `properties` app: `Building` + `Unit` per `06_database_schema.md` Domain 2.
- `Area`, `UnitType`, `UnitStatus` enums (already in `enums.md`).
- Indexes: `Building(owner_id)`, `Unit(building_id, status)`.

## API surface

- `GET/POST /api/v1/buildings`, `GET/PATCH/DELETE /api/v1/buildings/{id}`
- `POST /api/v1/buildings/{id}/units` (incl. bulk generate), `GET /api/v1/buildings/{id}/units`
- `GET/PATCH/DELETE /api/v1/units/{id}`
- `GET /api/v1/portfolio` (buildings + unit/occupancy summary)

## UI screens (from ledger)

- `home` → `/landlord/home` (🟢) — **T-009** (shell body; chart card placeholder for EPIC-09)
- `addBuilding` → `/properties/add` (🟢, 4-step) — **T-010, T-011**
- `portfolio` → `/landlord/home` portfolio list (🟢) — **T-012**
- `unit` → `/properties/unit/:id` (🟢) — **T-013**

## Feature flags introduced
None.

## Admin-portal config keys
- `area_options` (text/json) — the Dhaka area list, so admin can extend it later (default seeded from the Area enum).

## Test strategy
- Backend: building/unit CRUD; bulk unit generation correctness (floors×per-floor, schemes); `for_user` isolation (404 for others'); portfolio aggregation.
- Mobile: 4-step wizard flow (each step + back + review + save); map pin; unit generator math matches backend; portfolio + unit screens render all states.

## Acceptance criteria (epic-level)
- [ ] Landlord creates a building through all 4 wizard steps and saves it with auto-generated units.
- [ ] Map pin optional (OSM), address required and flows to DMP later.
- [ ] Unit generation matches the design (schemes, custom, removable) and the backend persists exactly what the UI shows.
- [ ] Portfolio lists buildings with unit/occupancy counts; unit detail shows rent/status.
- [ ] `for_user` isolation enforced (cross-landlord access → 404).
- [ ] **Screen coverage:** `home`, `addBuilding`, `portfolio`, `unit` built per design; ledger rows checked.
- [ ] `make test` + `make lint` pass for api + mobile.

## Task list

| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Building + Unit models, enums, migrations | backend | M | EPIC-00.T-005 | — |
| T-002 | Building managers (`for_user`) + permissions | backend | S | T-001, EPIC-02.T-002 | — |
| T-003 | Building CRUD endpoints | backend | M | T-002 | — |
| T-004 | Unit CRUD + bulk-generate endpoint | backend | M | T-002 | — |
| T-005 | Portfolio aggregation endpoint | backend | S | T-003, T-004 | — |
| T-006 | Seed `area_options` SystemConfig | backend | XS | EPIC-00.T-005 | — |
| T-007 | Flutter properties data layer (repos, models, providers) | mobile | M | T-003, T-004, T-005 | — |
| T-008 | Shared map-pin widget (flutter_map + OSM) | mobile | M | EPIC-00.T-008 | — |
| T-009 | Landlord home shell body | mobile | M | EPIC-02.T-004, T-007 | `home` |
| T-010 | Add-building wizard steps 1–2 (name/area, address/map) | mobile | M | T-007, T-008 | `addBuilding` |
| T-011 | Add-building wizard steps 3–4 (units generator, review, save) | mobile | M | T-010 | `addBuilding` |
| T-012 | Portfolio list screen | mobile | M | T-007 | `portfolio` |
| T-013 | Unit detail screen | mobile | M | T-007 | `unit` |
| T-014 | Unit generation logic shared/verified (UI↔API parity) | cross-cutting | S | T-004, T-011 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Unit-generation math diverges between UI and API | T-014 verifies parity with shared test vectors; backend bulk-generate is the source of truth |
| OSM tile usage limits | Cache tiles; attribution shown; it's free but be polite with requests |
| Wizard state complexity | Hold wizard state in one Riverpod controller; steps are views over it (mirrors the prototype's single-state approach) |
| Address vs map pin confusion | Address always required; pin optional and only fills address — exactly as the design shows |
