import { z } from "zod";
import { apiFetch } from "./client";
import { AI_CATEGORIES } from "./ai-providers";

/**
 * AI-usage data layer — EPIC-14.T-012.
 *
 * Consumes `GET /admin/api/ai-usage` (committed by EPIC-14.T-009, super/ops
 * only). The backend aggregates `AIUsageLog` by category and returns the
 * resource body directly (`core.responses.success`):
 *
 *   { by_category: [ { category, request_count, tokens_used, cost_usd,
 *                      call_count, success_count } ], totals: { … } }
 *
 * `cost_usd` is a decimal serialised as a string (USD, from `AIUsageLog`,
 * task §15) so we never lose precision to a JS float. Counts are integers.
 * Every payload is zod-validated at the boundary (coding standards §5).
 *
 * The endpoint does not yet carry per-row latency or a dedicated failover
 * event stream (the backend `AIUsageView`, T-009, aggregates volume only), so
 * the panel derives the visible signals — error rate and the failover/error
 * log — from the call vs. success counts it does return. The date filter is
 * forwarded as `from`/`to` query params; the server safely ignores params it
 * does not yet honour, so the UI is forward-compatible once T-009 grows a
 * date window.
 */

/** One aggregated usage row — keyed by AI category (AICategory, enums.md). */
export const aiUsageRowSchema = z.object({
  category: z.enum(AI_CATEGORIES),
  request_count: z.number(),
  tokens_used: z.number(),
  /** USD, decimal-as-string to preserve precision. */
  cost_usd: z.string(),
  /** Number of gateway calls logged (one AIUsageLog row each). */
  call_count: z.number(),
  /** How many of those calls succeeded. */
  success_count: z.number(),
});
export type AIUsageRow = z.infer<typeof aiUsageRowSchema>;

/** Platform-wide totals across every category. */
export const aiUsageTotalsSchema = z.object({
  request_count: z.number(),
  tokens_used: z.number(),
  cost_usd: z.string(),
  call_count: z.number(),
  success_count: z.number(),
});
export type AIUsageTotals = z.infer<typeof aiUsageTotalsSchema>;

export const aiUsageSchema = z.object({
  by_category: z.array(aiUsageRowSchema),
  totals: aiUsageTotalsSchema,
});
export type AIUsage = z.infer<typeof aiUsageSchema>;

/** Inclusive date window for the usage filter (ISO `YYYY-MM-DD`); empty = all. */
export interface AIUsageRange {
  from?: string;
  to?: string;
}

/** TanStack Query key for the AI-usage read, scoped by the active range. */
export function aiUsageQueryKey(range: AIUsageRange) {
  return ["admin", "ai-usage", range.from ?? "", range.to ?? ""] as const;
}

/** Fetch + validate aggregated AI usage for the given date window. */
export function fetchAIUsage(range: AIUsageRange = {}): Promise<AIUsage> {
  const params = new URLSearchParams();
  if (range.from) params.set("from", range.from);
  if (range.to) params.set("to", range.to);
  const query = params.toString();
  return apiFetch(
    "/admin/api/ai-usage" + (query ? "?" + query : ""),
    aiUsageSchema,
  );
}

/**
 * Error rate for a row as a fraction in `[0, 1]` — `(calls − successes) /
 * calls`. A row with no calls has no error rate (returns `null`) so the UI can
 * render an em-dash rather than a misleading `0%`.
 */
export function errorRate(row: {
  call_count: number;
  success_count: number;
}): number | null {
  if (row.call_count <= 0) return null;
  const failures = Math.max(row.call_count - row.success_count, 0);
  return failures / row.call_count;
}

/** Success rate as a fraction in `[0, 1]`, or `null` when there were no calls. */
export function successRate(row: {
  call_count: number;
  success_count: number;
}): number | null {
  const er = errorRate(row);
  return er === null ? null : 1 - er;
}
