import { z } from "zod";
import { ADMIN_ROLES } from "@/types/enums";
import { API_BASE_URL, apiErrorSchema, type ApiError } from "@/lib/api/client";

/**
 * Server-side admin auth API calls — EPIC-11.T-007.
 *
 * These run inside the Next route handlers (`app/api/auth/*`), never in the
 * browser, so the admin access token returned by the backend stays server-side
 * and is written straight into an HTTP-only cookie. Responses are validated
 * with zod at the boundary (coding standards §5).
 *
 * Backend contract (EPIC-11.T-003, mounted at `/admin/api/auth/`):
 *   POST /login       → { mfa_required: true, mfa_token } | { mfa_required: false, access, ... }
 *   POST /verify-mfa  → { access, expires_at, session_timeout_minutes, admin }
 */

const adminUserSchema = z.object({
  id: z.union([z.string(), z.number()]),
  email: z.string(),
  name: z.string(),
  role: z.enum(ADMIN_ROLES),
  scope: z.unknown().optional(),
  disabled: z.boolean(),
  last_login_at: z.string().nullable().optional(),
});

/** Successful, fully-authenticated result (no MFA, or MFA already passed). */
const tokenResultSchema = z.object({
  access: z.string(),
  expires_at: z.string(),
  session_timeout_minutes: z.number(),
  admin: adminUserSchema,
});
export type TokenResult = z.infer<typeof tokenResultSchema>;

/** Login may instead return an MFA challenge that must be completed. */
const mfaChallengeSchema = z.object({
  mfa_required: z.literal(true),
  mfa_token: z.string(),
});
export type MfaChallenge = z.infer<typeof mfaChallengeSchema>;

const loginResultSchema = z.union([
  mfaChallengeSchema,
  tokenResultSchema.extend({ mfa_required: z.literal(false) }),
]);
export type LoginResult = z.infer<typeof loginResultSchema>;

export class AuthApiError extends Error {
  readonly status: number;
  readonly body: ApiError | null;

  constructor(status: number, body: ApiError | null, message: string) {
    super(message);
    this.name = "AuthApiError";
    this.status = status;
    this.body = body;
  }
}

async function postAuth<TSchema extends z.ZodType>(
  path: string,
  schema: TSchema,
  body: unknown,
): Promise<z.infer<TSchema>> {
  const response = await fetch(`${API_BASE_URL}/admin/api/auth${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    cache: "no-store",
  });

  const json: unknown = await response.json().catch(() => null as unknown);

  if (!response.ok) {
    const parsed = apiErrorSchema.safeParse(json);
    throw new AuthApiError(
      response.status,
      parsed.success ? parsed.data : null,
      `Admin auth request failed: ${response.status} ${path}`,
    );
  }

  return schema.parse(json);
}

/** Step one: verify email + password; may return an MFA challenge. */
export function adminLogin(input: {
  email: string;
  password: string;
}): Promise<LoginResult> {
  return postAuth("/login", loginResultSchema, input);
}

/** Step two: exchange the MFA challenge + TOTP code for an admin access token. */
export function adminVerifyMfa(input: {
  mfa_token: string;
  code: string;
}): Promise<TokenResult> {
  return postAuth("/verify-mfa", tokenResultSchema, input);
}

/** Best-effort logout: revoke the access token on the backend. */
export async function adminLogout(token: string): Promise<void> {
  await fetch(`${API_BASE_URL}/admin/api/auth/logout`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  }).catch(() => undefined);
}
