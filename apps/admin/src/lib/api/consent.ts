import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Consent-records data layer — EPIC-16.T-007.
 *
 * Consumes `GET /admin/api/consent-records` (committed by EPIC-16.T-003). The
 * backend page-number-paginates the append-only `ConsentRecord` log and wraps
 * rows in the standard `{ results, pagination }` envelope
 * (`core.StandardPageNumberPagination`). Every field is zod-validated at the
 * boundary (coding standards §5).
 *
 * The log is read-only: `ConsentRecord` is append-only, so there is no
 * create/update/delete here — only the filterable list query.
 *
 * Filters mirror the backend query params (all optional, AND-combined):
 * `user`, `consent_type`, `granted_from`, `granted_to`, plus `page` for
 * pagination.
 */

/** Consent categories — mirrors `khatir.compliance.enums.ConsentType`. */
export const CONSENT_TYPES = [
  "pdpa_data_collection",
  "pdpa_nid_verification",
  "pdpa_data_sharing",
  "marketing",
] as const;
export type ConsentType = (typeof CONSENT_TYPES)[number];

/** Human label for each consent type (matches the backend choice labels). */
export const CONSENT_TYPE_LABELS: Record<ConsentType, string> = {
  pdpa_data_collection: "PDPA data collection",
  pdpa_nid_verification: "PDPA NID verification",
  pdpa_data_sharing: "PDPA data sharing",
  marketing: "Marketing",
};

export const consentRecordSchema = z.object({
  id: z.union([z.string(), z.number()]),
  user: z.number().nullable(),
  consent_type: z.string(),
  granted_at: z.string().nullable(),
  revoked_at: z.string().nullable(),
  expires_at: z.string().nullable(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type ConsentRecord = z.infer<typeof consentRecordSchema>;

export const consentPageSchema = z.object({
  results: z.array(consentRecordSchema),
  pagination: z.object({
    next: z.string().nullable(),
    previous: z.string().nullable(),
    count: z.number().nullable(),
  }),
});
export type ConsentPage = z.infer<typeof consentPageSchema>;

export interface ConsentFilters {
  /** Customer user id whose consent records to show. */
  user?: string;
  /** Exact match on a {@link ConsentType}. */
  consent_type?: string;
  /** Records granted on/after this ISO date. */
  granted_from?: string;
  /** Records granted on/before this ISO date. */
  granted_to?: string;
  /** Page-number cursor (from `pagination.next`/`previous`). */
  page?: string;
}

/** Build the `/admin/api/consent-records` path with the supplied filters. */
export function consentRecordsPath(filters: ConsentFilters = {}): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(filters)) {
    if (value !== undefined && value !== "") params.set(key, value);
  }
  const qs = params.toString();
  return qs
    ? `/admin/api/consent-records?${qs}`
    : "/admin/api/consent-records";
}

/** TanStack Query key for a consent-records page under the given filters. */
export function consentQueryKey(filters: ConsentFilters = {}) {
  return ["admin", "consent-records", filters] as const;
}

/** Fetch + validate a page of consent records. */
export function fetchConsentRecords(
  filters: ConsentFilters = {},
): Promise<ConsentPage> {
  return apiFetch(consentRecordsPath(filters), consentPageSchema);
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
