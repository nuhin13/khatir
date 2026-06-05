import { cookies } from "next/headers";

/**
 * Admin session cookie helpers — EPIC-11.T-007.
 *
 * The admin access token (and the transient MFA challenge token) live ONLY in
 * HTTP-only, SameSite=strict cookies set by server-side route handlers — never
 * in localStorage or client-readable JS. The browser flow proxies through
 * `app/api/auth/*` route handlers; those handlers call the backend, then write
 * the returned token into these cookies. The dashboard layout reads
 * {@link getSession} to gate access.
 */

/** Cookie holding the issued admin access token (JWT). */
export const ADMIN_SESSION_COOKIE = "khatir_admin_session";

/** Transient cookie holding the MFA challenge token between the two steps. */
export const ADMIN_MFA_COOKIE = "khatir_admin_mfa";

export interface AdminSession {
  token: string;
}

const baseCookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "strict" as const,
  path: "/",
};

/** Read the admin session from cookies, or null if absent. */
export async function getSession(): Promise<AdminSession | null> {
  const store = await cookies();
  const token = store.get(ADMIN_SESSION_COOKIE)?.value;
  if (!token) return null;
  return { token };
}

/**
 * Store the issued admin access token in the HTTP-only session cookie. The
 * cookie max-age tracks the backend session timeout (minutes) so the browser
 * drops it when the server-side session would expire anyway.
 */
export async function setSessionCookie(
  token: string,
  sessionTimeoutMinutes: number,
): Promise<void> {
  const store = await cookies();
  store.set(ADMIN_SESSION_COOKIE, token, {
    ...baseCookieOptions,
    maxAge: sessionTimeoutMinutes * 60,
  });
}

/** Clear the admin session cookie (logout / failed flow). */
export async function clearSessionCookie(): Promise<void> {
  const store = await cookies();
  store.delete(ADMIN_SESSION_COOKIE);
}

/**
 * Store the short-lived MFA challenge token so step two (`/login/mfa`) can
 * complete the exchange without ever exposing it to client JS.
 */
export async function setMfaCookie(mfaToken: string): Promise<void> {
  const store = await cookies();
  store.set(ADMIN_MFA_COOKIE, mfaToken, {
    ...baseCookieOptions,
    // Short window — the backend challenge token expires quickly anyway.
    maxAge: 5 * 60,
  });
}

/** Read the pending MFA challenge token, or null if there is no challenge. */
export async function getMfaCookie(): Promise<string | null> {
  const store = await cookies();
  return store.get(ADMIN_MFA_COOKIE)?.value ?? null;
}

/** Clear the MFA challenge cookie. */
export async function clearMfaCookie(): Promise<void> {
  const store = await cookies();
  store.delete(ADMIN_MFA_COOKIE);
}
