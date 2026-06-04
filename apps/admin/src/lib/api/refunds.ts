import { z } from "zod";
import { BILLING_CYCLES } from "@/types/enums";
import { apiFetch } from "./client";

/**
 * Refund-queue data layer — EPIC-12.T-009.
 *
 * Consumes the refund endpoints committed by EPIC-12.T-004:
 *
 * - `GET  /admin/api/billing/refunds`              — pending payment intents
 *   awaiting a finance decision (`RefundQueueView`), newest first, wrapped in a
 *   `{ results }` envelope.
 * - `POST /admin/api/billing/refunds/{id}/process` — approve or deny one intent
 *   (`RefundProcessView`). `approve` decides the outcome; `reason` is mandatory
 *   on a denial (also re-checked server-side so it can never be bypassed).
 *
 * For the MVP there is no dedicated PaymentIntent table: the queue rows are the
 * unresolved customer-realm `subscription.payment_intent` audit entries recorded
 * by the EPIC-10 subscribe stub (T-004 deviation note). Every payload is
 * zod-validated at the boundary (coding standards §5).
 */

/** One pending refund request (`_serialize_intent`, T-004). */
export const refundRequestSchema = z.object({
  id: z.union([z.string(), z.number()]),
  subscription_id: z.union([z.string(), z.number()]).nullable(),
  user_id: z.union([z.string(), z.number()]).nullable(),
  tier_key: z.string().nullable(),
  billing_cycle: z.enum(BILLING_CYCLES).nullable(),
  provider: z.string().nullable(),
  state: z.string().nullable(),
  created_at: z.string(),
});
export type RefundRequest = z.infer<typeof refundRequestSchema>;

/** The `{ results }` envelope returned by `GET .../refunds`. */
export const refundQueueSchema = z.object({
  results: z.array(refundRequestSchema),
});
export type RefundQueue = z.infer<typeof refundQueueSchema>;

/** The decision body echoed back by `POST .../{id}/process` (`process_refund`). */
export const refundDecisionSchema = z.object({
  intent_id: z.union([z.string(), z.number()]),
  decision: z.enum(["approved", "denied"]),
  state: z.string(),
  subscription_id: z.union([z.string(), z.number()]).nullable(),
  subscription_status: z.string().nullable(),
});
export type RefundDecision = z.infer<typeof refundDecisionSchema>;

/** TanStack Query key for the pending-refund queue. */
export const refundsQueryKey = ["admin", "billing", "refunds"] as const;

/** Fetch + validate the pending-refund queue. */
export async function fetchRefunds(): Promise<RefundRequest[]> {
  const page = await apiFetch("/admin/api/billing/refunds", refundQueueSchema);
  return page.results;
}

/**
 * Process one refund request. `approve === false` denies it and requires a
 * non-blank `reason` (enforced again server-side).
 */
export function processRefund(
  id: string | number,
  args: { approve: boolean; reason: string },
): Promise<RefundDecision> {
  return apiFetch(
    `/admin/api/billing/refunds/${id}/process`,
    refundDecisionSchema,
    {
      method: "POST",
      body: { approve: args.approve, reason: args.reason },
    },
  );
}
