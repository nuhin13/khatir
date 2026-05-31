# EPIC-12 · Admin — Pricing & Users

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-10, EPIC-11
**Tasks:** 10 · **External services:** none

---

## Business goal
Let staff edit pricing tiers live (with impact preview before applying) and manage user accounts (search, view, suspend, refund) — so the business runs without redeploys and support ops have the tools they need.

## Scope
**In:** Pricing tier editor (value + impact preview + reason + audit + rollout), tier change reflected in client config <60s. User search + detail + suspend/reactivate + manual subscription upgrade, refund queue.
**Out:** MFS billing integration (stub from EPIC-10 stays). New tier creation from scratch (edit existing).

## Dependencies
- EPIC-10 (PricingTier/Subscription models), EPIC-11 (admin shell + auth + audit writer).

## Data-model changes
None — edits existing PricingTier + Subscription.

## API surface (all `/admin/api/`)
- `GET/PATCH /pricing/tiers/{key}` — edit a tier (with preview).
- `GET /users` (search), `GET /users/{id}`, `POST /users/{id}/suspend`, `/reactivate`, `/upgrade-subscription`.
- `GET /billing/refunds`, `POST /billing/refunds/{id}/process`.

## UI (admin 🟣)
Pricing editor page, Users list + detail page, Refund queue. Design: `04_Admin_Portal_Khatir.md` §Pricing + §Users.

## Feature flags introduced
None.

## Acceptance criteria (epic-level)
- [ ] Tier edit + preview + reason captured; change reflected in /config/public <60s; audited.
- [ ] User search (phone/name/ID), detail, suspend/reactivate/manual-upgrade; all audited.
- [ ] Refund queue list + process action.
- [ ] Finance + super roles can edit pricing; ops + super can manage users.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | Tier edit endpoints (with impact preview) | backend | M | EPIC-10.T-001, EPIC-11.T-002 |
| T-002 | Cache invalidation on tier change (<60s) | backend | S | T-001 |
| T-003 | User search + detail + actions endpoints | backend | M | EPIC-11.T-001 |
| T-004 | Refund queue endpoints | backend | S | EPIC-10.T-004 |
| T-005 | Pricing editor page (Next.js) | admin | M | T-001, EPIC-11.T-008 |
| T-006 | Tier impact preview widget | admin | M | T-001 |
| T-007 | Users list + search page | admin | M | T-003 |
| T-008 | User detail + actions page | admin | M | T-003 |
| T-009 | Refund queue page | admin | S | T-004 |
| T-010 | Pricing change propagation test | cross-cutting | S | T-001, T-002 |
