import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Platform-dashboard data layer — EPIC-11.T-009.
 *
 * Consumes `GET /admin/api/dashboard` (committed by EPIC-11.T-005). The backend
 * returns the resource body directly (see `core.responses.success`), so the
 * payload is the KPI block + a live `health` block. Every field is zod-validated
 * at the boundary (coding standards §5).
 *
 * `recent_activity` models the activity feed (task §2 — last 20 admin audit
 * entries). The committed T-005 payload does not yet carry it, so the field is
 * optional and defaults to an empty list; the feed renders its empty state until
 * the audit list lands (EPIC-11.T-011). When the backend starts including it the
 * UI picks it up with no further change.
 */

const moneyPairSchema = z.object({
  all_time: z.string(),
  this_month: z.string(),
});

export const healthStatusSchema = z.enum(["ok", "down", "degraded"]);
export type HealthStatus = z.infer<typeof healthStatusSchema>;

export const healthSchema = z.object({
  app: z.string(),
  database: healthStatusSchema,
  cache: healthStatusSchema,
  status: healthStatusSchema,
});
export type Health = z.infer<typeof healthSchema>;

export const activityEntrySchema = z.object({
  id: z.union([z.string(), z.number()]),
  action: z.string(),
  actor: z.string().nullable().optional(),
  summary: z.string().nullable().optional(),
  created_at: z.string(),
});
export type ActivityEntry = z.infer<typeof activityEntrySchema>;

export const dashboardSchema = z.object({
  total_users: z.number(),
  active_landlords: z.number(),
  total_properties: z.number(),
  total_units: z.number(),
  occupied_units: z.number(),
  total_rent_collected: moneyPairSchema,
  dmp_forms_generated: z.number(),
  active_subscriptions: z.number(),
  health: healthSchema,
  recent_activity: z.array(activityEntrySchema).default([]),
});
export type Dashboard = z.infer<typeof dashboardSchema>;

/** TanStack Query key for the platform dashboard. */
export const dashboardQueryKey = ["admin", "dashboard"] as const;

/** Fetch + validate the platform dashboard payload. */
export function fetchDashboard(): Promise<Dashboard> {
  return apiFetch("/admin/api/dashboard", dashboardSchema);
}
