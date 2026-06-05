import { z } from "zod";
import { ROLES, LANGUAGES, BILLING_CYCLES, SUBSCRIPTION_STATUSES } from "@/types/enums";
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

/* ------------------------------------------------------------------------- *
 * User detail + actions — EPIC-12.T-008.
 *
 * Consumes the detail + action endpoints committed by EPIC-12.T-003:
 *
 * - `GET  /admin/api/users/{id}`                      — profile + subscription
 *   + usage counters + recent admin audit trail (`UserDetailView`).
 * - `POST /admin/api/users/{id}/suspend`              — deactivate; `reason`
 *   mandatory (`UserSuspendView`). Returns the updated user row.
 * - `POST /admin/api/users/{id}/reactivate`           — re-enable; optional
 *   `reason` (`UserReactivateView`). Returns the updated user row.
 * - `POST /admin/api/users/{id}/upgrade-subscription` — manual tier override;
 *   `tier_id` + mandatory `reason` (`UserUpgradeSubscriptionView`). Returns the
 *   updated subscription.
 *
 * The backend returns each resource body directly (`core.responses.success`).
 * Every payload is zod-validated at the boundary (coding standards §5).
 * ------------------------------------------------------------------------- */

/** A user's current subscription (AdminSubscriptionSerializer, T-003). */
export const adminSubscriptionSchema = z.object({
  id: z.union([z.string(), z.number()]),
  tier: z.union([z.string(), z.number()]),
  tier_key: z.string(),
  tier_label: z.string(),
  billing_cycle: z.enum(BILLING_CYCLES),
  status: z.enum(SUBSCRIPTION_STATUSES),
  start_at: z.string().nullable(),
  next_billing_at: z.string().nullable(),
});
export type AdminSubscription = z.infer<typeof adminSubscriptionSchema>;

/** A single audit-trail row (AdminAuditTrailSerializer, T-003). */
export const adminAuditTrailRowSchema = z.object({
  id: z.union([z.string(), z.number()]),
  action: z.string(),
  admin_user: z.union([z.string(), z.number()]).nullable(),
  reason: z.string().nullable(),
  before_json: z.record(z.string(), z.unknown()).nullable(),
  after_json: z.record(z.string(), z.unknown()).nullable(),
  created_at: z.string(),
});
export type AdminAuditTrailRow = z.infer<typeof adminAuditTrailRowSchema>;

/** Lightweight platform-usage counters (`_usage`, T-003). */
export const adminUsageSchema = z.object({
  buildings: z.number(),
  tenant_profiles: z.number(),
  subscriptions: z.number(),
});
export type AdminUsage = z.infer<typeof adminUsageSchema>;

/** Full user-detail payload (UserDetailView envelope, T-003). */
export const adminUserDetailSchema = z.object({
  user: adminUserRowSchema,
  subscription: adminSubscriptionSchema.nullable(),
  usage: adminUsageSchema,
  audit_trail: z.array(adminAuditTrailRowSchema),
});
export type AdminUserDetail = z.infer<typeof adminUserDetailSchema>;

/** TanStack Query key for a single user's detail. */
export function userDetailQueryKey(id: string | number) {
  return ["admin", "users", "detail", String(id)] as const;
}

/** Fetch + validate the full detail payload for one user. */
export function fetchUserDetail(
  id: string | number,
): Promise<AdminUserDetail> {
  return apiFetch(`/admin/api/users/${id}`, adminUserDetailSchema);
}

/** Suspend a user (deactivate + JWT blacklist). `reason` is mandatory. */
export function suspendUser(
  id: string | number,
  reason: string,
): Promise<AdminUserRow> {
  return apiFetch(`/admin/api/users/${id}/suspend`, adminUserRowSchema, {
    method: "POST",
    body: { reason },
  });
}

/** Reactivate a suspended user. `reason` is optional. */
export function reactivateUser(
  id: string | number,
  reason = "",
): Promise<AdminUserRow> {
  return apiFetch(`/admin/api/users/${id}/reactivate`, adminUserRowSchema, {
    method: "POST",
    body: { reason },
  });
}

/** Manually move a user onto `tierId` (optionally a different cycle). */
export function upgradeSubscription(
  id: string | number,
  args: { tierId: number; billingCycle?: string; reason: string },
): Promise<AdminSubscription> {
  return apiFetch(
    `/admin/api/users/${id}/upgrade-subscription`,
    adminSubscriptionSchema,
    {
      method: "POST",
      body: {
        tier_id: args.tierId,
        billing_cycle: args.billingCycle ?? "",
        reason: args.reason,
      },
    },
  );
}
