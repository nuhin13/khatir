# EPIC-10 · Pricing Tiers & Free Limit

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-04
**Tasks:** 9 · **External services:** MFS billing (bKash/Nagad) — can stub; real billing can trail

---

## Business goal
Implement the 6 admin-configurable pricing tiers and enforce the free-tier rule: first 2 tenants free, no NID verification — so the product can monetize while keeping the wedge accessible.

## User-visible outcome
A new landlord adds their first 2 tenants free. On the third, they see an upgrade prompt with the plan options. The `plan` screen shows their current tier, usage, and lets them switch. All tier values (prices, limits) come from the DB — the admin can change them without redeploy.

## Scope
**In scope**
- `PricingTier` + `Subscription` models seeded with the 6 default tiers.
- Tenant-count metering + free-limit enforcement (block creation past 2 on free tier).
- Upgrade prompt on reaching the limit.
- `plan` screen (🟢) — the plan & billing view.
- `/config/public` exposes current subscription state to the app.
- MFS payment stub (bKash/Nagad webhook integration can trail; upgrade flow records the intent).

**Out of scope**
- Real MFS payment processing (the billing flow can be completed later without blocking MVP; subscription can be manually upgraded via admin).
- Admin pricing editor (EPIC-12 — builds on this).

## Dependencies
- **Prerequisite:** EPIC-04 (tenant count from T-008's free-tier counter).
- **External:** MFS gateway (stub ok for MVP).
- **Design:** screen `plan`. See `07_design_map.md`.

## Data-model changes
- New `billing` app: `PricingTier` + `Subscription` per `06_database_schema.md` Domain 7.
- `BillingCycle`, `SubscriptionStatus` enums.
- Seeded with 6 default tiers (free, per_tenant, bundle_10, bundle_20, bundle_50, unlimited).

## API surface
- `GET /api/v1/pricing/tiers` — available tiers (public).
- `GET /api/v1/billing/subscription` — current user subscription + usage.
- `POST /api/v1/billing/subscribe` — subscribe/upgrade (stub payment).
- `/config/public` updated with subscription state + free_limit.

## UI screens (from ledger)
- `plan` → `/settings/plan` (🟢) — **T-007**

## Feature flags introduced
None.

## Admin-portal config keys
- `free_tier_tenant_limit` (int, default 2) — the only limit not in PricingTier because it governs the free tier before any subscription.
- `nid_verification_tiers` (json, e.g. ["bundle_10", "bundle_20", "bundle_50", "unlimited"]) — which tiers unlock NID verification.

## Test strategy
- Backend: tier seeding; metering blocks 3rd tenant on free tier; free-limit reads from config; subscription create/update; usage counts correct.
- Mobile: plan screen shows correct tier + usage + upgrade options; upgrade flow.

## Acceptance criteria (epic-level)
- [ ] 6 tiers seeded with correct limits/prices from DB.
- [ ] 3rd tenant creation blocked on free tier → upgrade prompt.
- [ ] `plan` screen shows current tier, usage (N/limit), upgrade options.
- [ ] Free-limit + tier values from DB (not hardcoded).
- [ ] NID verification gated by tier.
- [ ] **Screen `plan` built** per design; ledger row checked.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | PricingTier + Subscription models | backend | M | EPIC-00.T-005 |
| T-002 | Seed 6 default pricing tiers | backend | S | T-001 |
| T-003 | Tenant-count metering + free-limit enforcement | backend | M | T-001, EPIC-04.T-008 |
| T-004 | Subscription create/upgrade endpoint | backend | M | T-001 |
| T-005 | Pricing tiers + subscription in /config/public | backend | S | T-001 |
| T-006 | Seed pricing config keys | backend | XS | EPIC-00.T-005 |
| T-007 | Flutter plan screen | mobile | M | T-004, T-005 | `plan` |
| T-008 | Upgrade prompt (limit reached) | mobile | S | T-007 |
| T-009 | NID verification tier gate | cross-cutting | S | T-003, EPIC-04.T-005 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Real MFS integration delays MVP | Stub payment; admin can manually flip subscriptions; real billing trails |
| Tenant limit race condition (concurrent adds) | DB-level check in service (select_for_update or unique constraint) |
| Tier prices change mid-subscription | Subscription records the tier at time of subscribe; EPIC-12 handles retroactive |
