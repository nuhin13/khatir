import { z } from "zod";
import { apiFetch } from "./client";
import { featureFlagSchema, type FeatureFlag } from "./flags";

/**
 * Kill-switch data layer — EPIC-13.T-006.
 *
 * Consumes the emergency kill-switch endpoints committed by EPIC-13.T-003
 * (mounted at `/admin/api/killswitches`, **super only**):
 *
 * - `GET  /admin/api/killswitches`              — the 5 named kill-switches, in
 *   canonical display order (each is a `FeatureFlagSerializer` row; a switch is
 *   "live" while `enabled` is `true`).
 * - `POST /admin/api/killswitches/{key}/toggle` — flip a switch. Requires a
 *   **fresh TOTP re-confirmation** (`mfa_code`) even inside an active session,
 *   a mandatory `reason`, and an optional `lawyer_reference` (T-003 §15:
 *   intentional friction). Records an immutable `KillSwitchEvent`, audits the
 *   actor, and busts the `/config/public` cache (≤60s propagation). Returns the
 *   updated flag. A wrong/absent MFA code is rejected with 403.
 *
 * The wire shape of a kill-switch is exactly the feature-flag projection, so we
 * reuse {@link featureFlagSchema}. Every payload is zod-validated at the
 * boundary (coding standards §5). The list tolerates the bare-array or
 * `{ results }`-paginated envelope (mirroring the backend list view).
 */

/** A kill-switch is a feature-flag row; "live" ⇔ `enabled === true`. */
export type KillSwitch = FeatureFlag;

/** Tolerates the bare-array or `{ results }`-paginated list envelope. */
const killSwitchListSchema = z.union([
  z.array(featureFlagSchema),
  z.object({ results: z.array(featureFlagSchema) }),
]);

/** TanStack Query key for the kill-switch list. */
export const killSwitchesQueryKey = ["admin", "killswitches"] as const;

/** Body for a kill-switch toggle — MFA + mandatory reason + optional ref. */
export interface KillSwitchToggleInput {
  key: string;
  mfaCode: string;
  reason: string;
  lawyerReference?: string;
}

/** Fetch + validate the 5 named kill-switches (super only). */
export async function fetchKillSwitches(): Promise<KillSwitch[]> {
  const body = await apiFetch("/admin/api/killswitches", killSwitchListSchema);
  return Array.isArray(body) ? body : body.results;
}

/**
 * Flip a kill-switch. Sends the fresh MFA code, reason, and optional lawyer
 * reference to the backend (which re-confirms the TOTP, records the immutable
 * event, and busts the public-config cache). Returns the updated switch.
 */
export function toggleKillSwitch(
  input: KillSwitchToggleInput,
): Promise<KillSwitch> {
  return apiFetch(
    "/admin/api/killswitches/" + input.key + "/toggle",
    featureFlagSchema,
    {
      method: "POST",
      body: {
        mfa_code: input.mfaCode,
        reason: input.reason,
        lawyer_reference: input.lawyerReference ?? "",
      },
    },
  );
}
