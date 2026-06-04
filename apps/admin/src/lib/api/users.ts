import { z } from "zod";
import { ROLES, LANGUAGES } from "@/types/enums";
import { apiFetch } from "./client";

/**
 * Admin user-management data layer — EPIC-12.T-007.
 *
 * Consumes `GET /admin/api/users` (committed by EPIC-12.T-003). The backend
 * searches `accounts.User` by phone / name / ID / masked-NID via the single
 * `q` query param, page-number-paginates the result (`core.pagination`), and
 * wraps rows in the standard `{ results, pagination }` envelope. Each row is
 * the compact `AdminUserListSerializer` projection — the raw phone is present
 * but the list view renders only the server-supplied `masked_phone` (privacy:
 * spec §4.2, "never shows full NID/phone in list"). Every field is
 * zod-validated at the boundary (coding standards §5).
 */

export const adminUserRowSchema = z.object({
  id: z.union([z.string(), z.number()]),
  name: z.string(),
  /** Raw phone — present on the wire but never rendered in the list. */
  phone: z.string(),
  /** Server-masked phone, e.g. `+8801•••••89`. The only phone shown in list. */
  masked_phone: z.string(),
  role: z.enum(ROLES),
  language: z.enum(LANGUAGES),
  is_active: z.boolean(),
  last_login_at: z.string().nullable(),
  created_at: z.string(),
});
export type AdminUserRow = z.infer<typeof adminUserRowSchema>;

export const adminUserPageSchema = z.object({
  results: z.array(adminUserRowSchema),
  pagination: z.object({
    next: z.string().nullable(),
    previous: z.string().nullable(),
    count: z.number().nullable(),
  }),
});
export type AdminUserPage = z.infer<typeof adminUserPageSchema>;

export interface UserSearchFilters {
  /** Free-text search across phone / name / ID / masked-NID. */
  q?: string;
  /** 1-based page number (page-number pagination). */
  page?: number;
}

/** Build the `/admin/api/users` path with the supplied search + page. */
export function usersSearchPath(filters: UserSearchFilters = {}): string {
  const params = new URLSearchParams();
  if (filters.q !== undefined && filters.q !== "") params.set("q", filters.q);
  if (filters.page !== undefined && filters.page > 1) {
    params.set("page", String(filters.page));
  }
  const qs = params.toString();
  return qs ? `/admin/api/users?${qs}` : "/admin/api/users";
}

/** TanStack Query key for a user-search page under the given filters. */
export function usersQueryKey(filters: UserSearchFilters = {}) {
  return ["admin", "users", filters] as const;
}

/** Fetch + validate a page of user-search results. */
export function fetchUsers(
  filters: UserSearchFilters = {},
): Promise<AdminUserPage> {
  return apiFetch(usersSearchPath(filters), adminUserPageSchema);
}
