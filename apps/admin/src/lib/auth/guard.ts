import { cookies } from "next/headers";

/**
 * Auth guard STUB. Real email+password+MFA session handling lands in EPIC-11.
 *
 * For now we only check for the presence of a fake session cookie. The
 * dashboard layout calls {@link requireSession} and redirects to /login when
 * no session is present.
 */

export const ADMIN_SESSION_COOKIE = "khatir_admin_session";

export interface AdminSession {
  token: string;
}

/** Read the (fake) admin session from cookies, or null if absent. */
export async function getSession(): Promise<AdminSession | null> {
  const store = await cookies();
  const token = store.get(ADMIN_SESSION_COOKIE)?.value;
  if (!token) return null;
  return { token };
}
