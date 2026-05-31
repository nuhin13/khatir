# EPIC-02 · Role & Profile Management

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-01
**Tasks:** 8 · **External services:** none

---

## Business goal

After a user verifies their phone (EPIC-01), let them declare who they are — Landlord, Building Manager, or Tenant — and route them into the matching role-specific app experience. Provide a basic profile (name, language toggle, role switch) via the More menu. This turns one codebase into three tailored shells without three apps.

## User-visible outcome

A newly-verified user lands on the **role chooser** (Landlord is marked "most common"), picks a role, and is taken to that role's home shell with its own bottom navigation. From the **More** menu they can see their profile, switch language (bn/en), switch role, re-view onboarding, and log out. Returning users skip the chooser and land directly in their role shell.

## Scope

**In scope**
- Role chooser screen (`roleChooser`) — 3 role cards (landlord/manager/tenant) with perks, "most common" badge on landlord.
- Persist the chosen role to the backend (`User.role`) via a profile endpoint.
- Three role shells (landlord / manager / tenant) using `StatefulShellRoute` with role-specific bottom nav.
- Bottom nav per the design: Home · Charts · Add (center FAB) · Rent · More — with the Home target and visible tabs adapting to role.
- More menu (`more`) — profile row, plan/billing link, language toggle, role switch, about, logout.
- Profile endpoints: get/update name + language + role.
- Router redirect logic: verified-but-no-role → chooser; role set → that shell; wrong-role access → bounce to own shell.

**Out of scope**
- The actual feature screens behind the nav (home dashboard = EPIC-03/09, rent = EPIC-07, add-tenant = EPIC-04, charts = EPIC-09). EPIC-02 wires the shells + nav with placeholder bodies that later epics fill.
- Manager multi-owner functionality (EPIC-22) and Tenant app features (EPIC-19) — those shells exist here but their inner screens come later. EPIC-02 builds the landlord shell fully (its tabs are filled by MVP epics) and stubs manager/tenant shells.
- Caretaker role (EPIC-25, P2).
- Cross-role switching for the *same* person being both landlord and tenant — deferred (per your instruction).

## Dependencies

- **Prerequisite:** EPIC-01 (auth + `User` model + the `/home` placeholder seam that T-012 left with a `// TODO(EPIC-02) role routing` marker).
- **External:** none.
- **Design:** screens `roleChooser`, `more`; role shells derived from `home`/`mgrHome`/`tenHome` + the `bottomnav()` helper in `proto/ui.js`. See `07_design_map.md`.

## Data-model changes

- No new tables. Uses existing `User.role` + `User.language` (from EPIC-01 `accounts`). May add a lightweight profile serializer/endpoint. `Role` enum already defined.

## API surface

- `GET /api/v1/profile` — current user's profile (name, role, language, phone).
- `PATCH /api/v1/profile` — update name / language / role.
- (Role is also returned in the JWT + `/auth/me`; profile endpoint is the editable surface.)

## UI screens (from the ledger)

- `roleChooser` → `/role` (🟢 mobile) — **EPIC-02 task T-005**
- `more` → `/landlord/more` (and manager/tenant equivalents) (🟢 mobile) — **EPIC-02 task T-007**
- Three role shells (`/landlord`, `/manager`, `/tenant`) with bottom nav — **EPIC-02 tasks T-004, T-006**

## Feature flags introduced

None.

## Admin-portal config keys

None new.

## Test strategy

- Backend: profile get/update; role change persists + reflects in next token/me; validation (invalid role/language rejected).
- Mobile: role chooser selects + persists role and routes to correct shell; redirect guard (no-role→chooser, wrong-role→own shell); language toggle re-renders; logout. Widget tests for `roleChooser` and `more`; shell nav tests.

## Acceptance criteria (epic-level)

- [ ] Verified user with no role → role chooser; picking a role persists it and routes to that shell.
- [ ] Three role shells exist with correct bottom nav (Home/Charts/Add/Rent/More; home target swaps per role).
- [ ] Landlord shell nav wired (tabs route to the right places; bodies may be placeholders pending later epics).
- [ ] Manager + Tenant shells exist as stubs (full features in EPIC-22 / EPIC-19).
- [ ] More menu: profile, language toggle (bn/en re-renders app), role switch, re-view onboarding, logout.
- [ ] Router guards: no-role→chooser, wrong-role→own shell, logout→phone.
- [ ] Profile endpoints work; role/language changes persist and survive restart.
- [ ] **Screen coverage:** `roleChooser` + `more` built per design; ledger rows checked.
- [ ] `make test` + `make lint` pass for api + mobile.

## Task list

| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | Profile endpoints (get/update role, name, language) | backend | S | EPIC-01.T-006 | — |
| T-002 | Role enum + permission helpers (role gating base) | backend | XS | EPIC-01.T-002 | — |
| T-003 | Flutter profile repository + auth-state role integration | mobile | S | EPIC-01.T-011, T-001 | — |
| T-004 | Role shell scaffolding (StatefulShellRoute, 3 shells) | mobile | M | EPIC-01.T-012, T-003 | shells |
| T-005 | Role chooser screen | mobile | M | T-004 | `roleChooser` |
| T-006 | Bottom nav component + per-role tabs | mobile | M | T-004 | (nav) |
| T-007 | More menu screen (profile, language, role switch, logout) | mobile | M | T-004, T-003 | `more` |
| T-008 | Router role-redirect guards + replace EPIC-01 /home seam | mobile | S | T-004, T-005 | — |

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Manager/Tenant shells tempting to over-build now | Explicitly stub them; full features are EPIC-22 / EPIC-19. Build landlord shell fully. |
| Role switch causing stale token role | On role change, refresh token or re-fetch `/auth/me`; DB is source of truth for role. |
| Bottom-nav tabs point at not-yet-built screens | Tabs route to placeholder bodies with a clear marker; later epics replace the bodies, not the nav. |
| Language toggle not re-rendering | Use the `localeProvider` from EPIC-00 T-008; toggling updates app locale reactively. |
