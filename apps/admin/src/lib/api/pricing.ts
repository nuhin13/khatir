import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Pricing-tier data layer — EPIC-12.T-005.
 *
 * Consumes the admin pricing endpoints committed by EPIC-12.T-001:
 *
 * - `GET   /admin/api/pricing/tiers`               — full tier list (active +
 *   inactive), in plan-picker order.
 * - `POST  /admin/api/pricing/tiers/{key}/preview` — read-only impact of a
 *   proposed (partial) change: subscribers affected + monthly revenue delta.
 * - `PATCH /admin/api/pricing/tiers/{key}`         — apply a change; a `reason`
 *   is mandatory (audited). Busts the `/config/public` cache (≤60s propagation).
 *
 * The backend returns the resource body directly (`core.responses.success`).
 * Every payload is zod-validated at the boundary (coding standards §5). Prices
 * are decimals serialised as strings on the wire; they stay strings here and are
 * coerced to numbers only where arithmetic/formatting needs it.
 */

/** Full admin read projection of a pricing tier (PricingTierAdminSerializer). */
export const pricingTierSchema = z.object({
  id: z.union([z.string(), z.number()]),
  key: z.string(),
  label: z.string(),
  label_bn: z.string(),
  tenant_min: z.number(),
  tenant_max: z.number().nullable(),
  monthly_price: z.string().nullable(),
  annual_price: z.string().nullable(),
  includes_verification: z.boolean(),
  included_credits: z.number(),
  active: z.boolean(),
  sort_order: z.number(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type PricingTier = z.infer<typeof pricingTierSchema>;

/** The editable subset of a tier (everything except key/id/timestamps). */
export const tierEditableSchema = pricingTierSchema.pick({
  label: true,
  label_bn: true,
  tenant_min: true,
  tenant_max: true,
  monthly_price: true,
  annual_price: true,
  includes_verification: true,
  included_credits: true,
  active: true,
  sort_order: true,
});
export type TierEditable = z.infer<typeof tierEditableSchema>;

/** A proposed (partial) set of tier changes for preview/edit. */
export type TierChanges = Partial<TierEditable>;

/** Read-only impact payload (compute_impact in pricing_services). */
export const tierImpactResponseSchema = z.object({
  subscribers_affected: z.number(),
  monthly_revenue_delta: z.string(),
});
export type TierImpactResponse = z.infer<typeof tierImpactResponseSchema>;

/** TanStack Query key for the pricing-tier list. */
export const pricingTiersQueryKey = ["admin", "pricing", "tiers"] as const;

/** Fetch + validate every pricing tier (plan-picker order). */
export function fetchPricingTiers(): Promise<PricingTier[]> {
  return apiFetch(
    "/admin/api/pricing/tiers",
    z.array(pricingTierSchema),
  );
}

/** Preview the impact of applying `changes` to the tier `key` (read-only). */
export function previewTier(
  key: string,
  changes: TierChanges,
): Promise<TierImpactResponse> {
  return apiFetch("/admin/api/pricing/tiers/" + key + "/preview", tierImpactResponseSchema, {
    method: "POST",
    body: changes,
  });
}

/** Apply `changes` to the tier `key` with a mandatory `reason` (audited). */
export function editTier(
  key: string,
  changes: TierChanges,
  reason: string,
): Promise<PricingTier> {
  return apiFetch("/admin/api/pricing/tiers/" + key, pricingTierSchema, {
    method: "PATCH",
    body: { ...changes, reason },
  });
}
