import { z } from "zod";
import { apiFetch } from "./client";

/**
 * Feature-flag data layer — EPIC-13.T-005.
 *
 * Consumes the admin feature-flag endpoints committed by EPIC-13.T-002
 * (mounted at `/admin/api/flags`, super/ops only):
 *
 * - `GET   /admin/api/flags`               — list every flag (FeatureFlagSerializer).
 * - `PATCH /admin/api/flags/{key}/toggle`  — flip `enabled`, record the actor,
 *   audit-log it, and bust the `/config/public` cache (≤60s propagation). Returns
 *   the updated flag.
 *
 * `enabled` is flipped *only* via the dedicated toggle endpoint — it is
 * read-only on the plain serializer — so this console exposes exactly that one
 * mutation. Every payload is zod-validated at the boundary (coding standards §5).
 * The DRF `ListModelMixin` may return either a bare array or a paginated
 * `{ results }` envelope depending on the global pagination setting, so the list
 * fetch tolerates both shapes (mirroring the backend test in
 * `test_flag_endpoints.py::test_list_flags`).
 */

/** Wire scope of a feature flag (FlagScope: global / role / user). */
export const FLAG_SCOPES = ["global", "role", "user"] as const;
export type FlagScope = (typeof FLAG_SCOPES)[number];

/** Read/write projection of a FeatureFlag (FeatureFlagSerializer, T-002). */
export const featureFlagSchema = z.object({
  id: z.union([z.string(), z.number()]),
  key: z.string(),
  description: z.string(),
  scope: z.enum(FLAG_SCOPES),
  enabled: z.boolean(),
  value_json: z.unknown().nullable(),
  updated_by: z.union([z.string(), z.number()]).nullable(),
  created_at: z.string(),
  updated_at: z.string(),
});
export type FeatureFlag = z.infer<typeof featureFlagSchema>;

/** Tolerates the bare-array or `{ results }`-paginated list envelope. */
const flagListSchema = z.union([
  z.array(featureFlagSchema),
  z.object({ results: z.array(featureFlagSchema) }),
]);

/** TanStack Query key for the feature-flag list. */
export const featureFlagsQueryKey = ["admin", "flags"] as const;

/** Fetch + validate every feature flag. */
export async function fetchFeatureFlags(): Promise<FeatureFlag[]> {
  const body = await apiFetch("/admin/api/flags", flagListSchema);
  return Array.isArray(body) ? body : body.results;
}

/** Toggle a flag's `enabled` state (audited + cache-busted). */
export function toggleFeatureFlag(key: string): Promise<FeatureFlag> {
  return apiFetch("/admin/api/flags/" + key + "/toggle", featureFlagSchema, {
    method: "PATCH",
  });
}
