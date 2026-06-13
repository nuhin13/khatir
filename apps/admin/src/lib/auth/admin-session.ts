import { z } from "zod";
import { ADMIN_ROLES } from "@/types/enums";
import type { AdminRole } from "@/types/enums";
import { API_BASE_URL } from "@/lib/api/client";
import { getSession } from "./session";

/**
 * Authenticated admin resolution — EPIC-11.T-008.
 *
 * The dashboard shell's real session guard: it reads the HTTP-only session
 * cookie (set during the T-007 login/MFA flow), then resolves the authenticated
 * staff member by calling the backend `GET /admin/api/auth/me` server-side with
 * the bearer token. This runs only on the server (the token never reaches the
 * browser), and the response is zod-validated at the boundary (coding
 * standards §5).
 *
 * A missing/expired cookie, a 401/403 from the backend (revoked or disabled
 * account), or a malformed response all resolve to `null` — the layout then
 * redirects to `/login`. The `role` drives the role-aware sidebar; the JWT
 * `exp` claim drives the client-side session-expiry warning.
 */

/** Shape returned by the backend `/me` endpoint (AdminUserSerializer). */
const adminMeSchema = z.object({
  id: z.union([z.string(), z.number()]),
  email: z.string(),
  name: z.string(),
  role: z.enum(ADMIN_ROLES),
  scope: z.unknown().optional(),
  disabled: z.boolean(),
  last_login_at: z.string().nullable().optional(),
});

export interface AdminMe {
  id: string | number;
  email: string;
  name: string;
  role: AdminRole;
  disabled: boolean;
}

export interface AuthenticatedAdmin extends AdminMe {
  /** Unix epoch seconds at which the session token expires, or null if absent. */
  expiresAt: number | null;
}

/**
 * Decode the `exp` claim from a JWT without verifying the signature. Verifying
 * is the backend's job (it owns the signing key); here we only need the expiry
 * to drive the client-side timeout warning. Returns null if unparseable.
 */
function readTokenExpiry(token: string): number | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const payloadJson = Buffer.from(parts[1], "base64url").toString("utf-8");
    const payload: unknown = JSON.parse(payloadJson);
    if (
      typeof payload === "object" &&
      payload !== null &&
      "exp" in payload &&
      typeof (payload as { exp: unknown }).exp === "number"
    ) {
      return (payload as { exp: number }).exp;
    }
  } catch {
    return null;
  }
  return null;
}

/**
 * Resolve the currently authenticated admin, or null if there is no valid
 * session. Used by the dashboard layout as the real session guard.
 */
export async function getAuthenticatedAdmin(): Promise<AuthenticatedAdmin | null> {
  const session = await getSession();
  if (!session) return null;

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}/admin/api/auth/me`, {
      headers: { Authorization: `Bearer ${session.token}` },
      cache: "no-store",
    });
  } catch {
    // Backend unreachable — fail closed (treat as unauthenticated).
    return null;
  }

  if (!response.ok) return null;

  const json: unknown = await response.json().catch(() => null);
  const parsed = adminMeSchema.safeParse(json);
  if (!parsed.success) return null;

  const me = parsed.data;
  // A disabled account must not reach the shell, even with a live token.
  if (me.disabled) return null;

  return {
    id: me.id,
    email: me.email,
    name: me.name,
    role: me.role,
    disabled: me.disabled,
    expiresAt: readTokenExpiry(session.token),
  };
}
