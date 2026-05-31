# EPIC-25 · Gatekeeper / Caretaker (Visitor & Building Ops)

**Phase:** P2 · **Status:** todo · **Depends on:** EPIC-03, EPIC-02
**Tasks:** 14 · **External services:** none

---

## Business goal
Give building caretakers/gatekeepers a lightweight tool to log visitors and building events, and let visitors self-register via a web-link at the gate — a building-operations layer that deepens the product's role in daily building life.

## User-visible outcome
A caretaker logs in (caretaker role) to a simple home (`careHome`) showing today's activity; reviews visitor entries (`careReview`); and browses the visitor/event log (`careLog`). Visitors at the gate self-register via a no-install web page (`webVisitor`) that routes to the caretaker for review.

## Scope
**In:** Caretaker role experience (home, review, log). Visitor self-registration web-link (`webVisitor`). VisitorEntry + building event log. Caretaker assigned to building(s) by the owner/manager. The 4 remaining screens.
**Out:** Access-control hardware integration. Facial recognition. Anything beyond logging (no enforcement).

## Dependencies
EPIC-02 (caretaker role shell), EPIC-03 (building/unit), EPIC-07 (web-link token pattern), EPIC-04 (encrypted storage for visitor photo).

## Data-model changes
- `CaretakerAssignment`: caretaker User FK, building FK, assigned_by, status.
- `VisitorEntry`: building FK, unit FK nullable, visitor_name, purpose, photo_ref nullable, status (pending/approved/denied), logged_by nullable, created_at.

## API surface
- Caretaker: `GET /api/v1/caretaker/home`, `GET /caretaker/visitors`, `POST /caretaker/visitors/{id}/review`.
- Public (token): `GET /v/{token}` (visitor self-register page), `POST /v/{token}` (submit).
- Owner/manager: `POST /api/v1/buildings/{id}/caretakers` (assign).

## UI screens (from ledger)
- `careHome` → `/caretaker/home` (🟢) — **T-006**
- `careReview` → `/caretaker/review` (🟢) — **T-007**
- `careLog` → `/caretaker/log` (🟢) — **T-008**
- `webVisitor` → `/v/:token` (🌐 Django template) — **T-005**

## Feature flags introduced
- `gatekeeper_enabled` (default on).

## Acceptance criteria (epic-level)
- [ ] Owner/manager assigns a caretaker to a building.
- [ ] Caretaker home shows today's visitor activity; review approve/deny; full log browseable.
- [ ] Visitor self-registers via web-link (no app) → caretaker review queue.
- [ ] Caretaker scoped to assigned buildings only.
- [ ] **Screen coverage:** careHome, careReview, careLog, webVisitor built — **completes all 44 screens**.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on | Screen(s) |
|------|-------|-------|------|-----------|-----------|
| T-001 | CaretakerAssignment + VisitorEntry models | backend | M | EPIC-03.T-001 | — |
| T-002 | Caretaker assignment + scoping endpoints | backend | M | T-001, EPIC-03.T-002 | — |
| T-003 | Caretaker home + visitor review endpoints | backend | M | T-001 | — |
| T-004 | Visitor web-link token + submit endpoint | backend | M | EPIC-07.T-002, T-001 | — |
| T-005 | Visitor self-register web page | backend(web) | M | T-004 | `webVisitor` 🌐 |
| T-006 | Caretaker home screen | mobile | M | EPIC-02.T-004, T-003 | `careHome` |
| T-007 | Caretaker review screen | mobile | M | T-003 | `careReview` |
| T-008 | Caretaker log screen | mobile | M | T-003 | `careLog` |
| T-009 | Caretaker data layer (mobile) | mobile | M | T-003 | — |
| T-010 | Caretaker shell wiring (fill EPIC-02) | mobile | S | T-006, EPIC-02.T-004 | — |
| T-011 | Assign-caretaker UI (owner/manager side) | mobile | S | T-002 | — |
| T-012 | Seed gatekeeper config + flag | backend | XS | EPIC-13.T-001 | — |
| T-013 | Caretaker scoping test (assigned buildings only) | cross-cutting | S | T-002 | — |
| T-014 | Final screen-coverage verification (all 44) | cross-cutting | S | T-008 | — |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Caretaker sees buildings they're not assigned to | T-013 scoping test; for_user-style caretaker scope |
| Visitor photo privacy | Encrypted storage (EPIC-04); retention policy; consent notice on web page |
| Web-link abuse at gate | Token-scoped per building; rate-limited |
