import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Audit-log data layer — EPIC-11.T-011.
 *
 * Consumes `GET /admin/api/audit-log` (committed by this task). The backend
 * cursor-paginates the immutable `AdminAuditEntry` ledger newest-first and wraps
 * rows in the standard `{ results, pagination }` envelope (`core.pagination`).
 * Every field is zod-validated at the boundary (coding standards §5).
 *
 * Filters mirror the backend query params (all optional, AND-combined):
 * `admin_user`, `action`, `entity_type`, `from`, `to`, plus the opaque cursor
 * `cursor` for pagination.
 */

export const auditEntrySchema = z.object({
  id: z.union([z.string(), z.number()]),
  action: z.string(),
  actor: z.string(),
  admin_user: z.number().nullable(),
  entity_type: z.string(),
  entity_id: z.string(),
  before_json: z.record(z.string(), z.unknown()).nullable(),
  after_json: z.record(z.string(), z.unknown()).nullable(),
  ip: z.string().nullable(),
  reason: z.string(),
  created_at: z.string(),
});
export type AuditEntry = z.infer<typeof auditEntrySchema>;

export const auditPageSchema = z.object({
  results: z.array(auditEntrySchema),
  pagination: z.object({
    next: z.string().nullable(),
    previous: z.string().nullable(),
    count: z.number().nullable(),
  }),
});
export type AuditPage = z.infer<typeof auditPageSchema>;

export interface AuditFilters {
  admin_user?: string;
  action?: string;
  entity_type?: string;
  from?: string;
  to?: string;
  /** Opaque cursor for the next/previous page (from `pagination.next`). */
  cursor?: string;
}

/** Build the `/admin/api/audit-log` path with the supplied filters. */
export function auditLogPath(filters: AuditFilters = {}): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(filters)) {
    if (value !== undefined && value !== "") params.set(key, value);
  }
  const qs = params.toString();
  return qs ? `/admin/api/audit-log?${qs}` : "/admin/api/audit-log";
}

/** TanStack Query key for an audit-log page under the given filters. */
export function auditQueryKey(filters: AuditFilters = {}) {
  return ["admin", "audit-log", filters] as const;
}

/** Fetch + validate a page of audit-log entries. */
export function fetchAuditLog(filters: AuditFilters = {}): Promise<AuditPage> {
  return apiFetch(auditLogPath(filters), auditPageSchema);
}
