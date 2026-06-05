import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Data-request queue data layer — EPIC-16.T-008.
 *
 * Consumes the PDPA data-request endpoints committed by EPIC-16.T-004
 * (`compliance/data_request_views.py`):
 *
 * - `GET  /admin/api/data-requests`              — page-number-paginated,
 *   filterable queue of export / erasure requests wrapped in the standard
 *   `{ results, pagination }` envelope (`core.StandardPageNumberPagination`).
 *   Filters: `status`, `type`, `sla` (`overdue` / `due_soon` / `on_track`).
 * - `POST /admin/api/data-requests/{id}/process` — approve or reject a *pending*
 *   request. Body `{ action: "approve" | "reject", reason }`; `reason` is
 *   mandatory on a rejection (re-checked server-side). The endpoint returns the
 *   updated `DataRequest` resource directly (`core.responses.success`).
 *
 * Every payload is zod-validated at the boundary (coding standards §5).
 */

/** Request kinds — mirrors `khatir.compliance.enums.DataRequestType`. */
export const DATA_REQUEST_TYPES = ["export", "delete"] as const;
export type DataRequestType = (typeof DATA_REQUEST_TYPES)[number];

export const DATA_REQUEST_TYPE_LABELS: Record<DataRequestType, string> = {
  export: "Export",
  delete: "Delete",
};

/** Lifecycle states — mirrors `khatir.compliance.enums.DataRequestStatus`. */
export const DATA_REQUEST_STATUSES = [
  "pending",
  "processing",
  "completed",
  "rejected",
] as const;
export type DataRequestStatus = (typeof DATA_REQUEST_STATUSES)[number];

export const DATA_REQUEST_STATUS_LABELS: Record<DataRequestStatus, string> = {
  pending: "Pending",
  processing: "Processing",
  completed: "Completed",
  rejected: "Rejected",
};

/** SLA classification — derived server-side from `sla_due` (`sla_state`). */
export const SLA_STATES = ["overdue", "due_soon", "on_track"] as const;
export type SlaState = (typeof SLA_STATES)[number];

export const SLA_STATE_LABELS: Record<SlaState, string> = {
  overdue: "Overdue",
  due_soon: "Due soon",
  on_track: "On track",
};

export const dataRequestSchema = z.object({
  id: z.union([z.string(), z.number()]),
  user: z.number().nullable(),
  request_type: z.string(),
  status: z.string(),
  sla_due: z.string().nullable(),
  sla_state: z.string(),
  completed_at: z.string().nullable(),
  handled_by: z.number().nullable(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type DataRequest = z.infer<typeof dataRequestSchema>;

export const dataRequestPageSchema = z.object({
  results: z.array(dataRequestSchema),
  pagination: z.object({
    next: z.string().nullable(),
    previous: z.string().nullable(),
    count: z.number().nullable(),
  }),
});
export type DataRequestPage = z.infer<typeof dataRequestPageSchema>;

export interface DataRequestFilters {
  /** Exact match on a {@link DataRequestStatus}. */
  status?: string;
  /** Exact match on a {@link DataRequestType}. */
  type?: string;
  /** SLA bucket — `overdue` / `due_soon` / `on_track`. */
  sla?: string;
  /** Page-number cursor (from `pagination.next`/`previous`). */
  page?: string;
}

/** Build the `/admin/api/data-requests` path with the supplied filters. */
export function dataRequestsPath(filters: DataRequestFilters = {}): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(filters)) {
    if (value !== undefined && value !== "") params.set(key, value);
  }
  const qs = params.toString();
  return qs ? `/admin/api/data-requests?${qs}` : "/admin/api/data-requests";
}

/** TanStack Query key for a data-request page under the given filters. */
export function dataRequestsQueryKey(filters: DataRequestFilters = {}) {
  return ["admin", "data-requests", filters] as const;
}

/** Fetch + validate a page of data requests. */
export function fetchDataRequests(
  filters: DataRequestFilters = {},
): Promise<DataRequestPage> {
  return apiFetch(dataRequestsPath(filters), dataRequestPageSchema);
}

/**
 * Process one *pending* data request. `approve === false` rejects it and
 * requires a non-blank `reason` (enforced again server-side). Resolves to the
 * updated {@link DataRequest} as echoed back by the endpoint.
 */
export function processDataRequest(
  id: string | number,
  args: { approve: boolean; reason: string },
): Promise<DataRequest> {
  return apiFetch(`/admin/api/data-requests/${id}/process`, dataRequestSchema, {
    method: "POST",
    body: {
      action: args.approve ? "approve" : "reject",
      reason: args.reason,
    },
  });
}

/** Extract the `page` query value from a DRF page-number pagination link. */
export function pageFromLink(link: string | null): string | undefined {
  if (!link) return undefined;
  try {
    return new URL(link).searchParams.get("page") ?? undefined;
  } catch {
    return undefined;
  }
}
