/**
 * Auth guard — EPIC-11.T-007.
 *
 * The dashboard layout calls {@link getSession} and redirects to /login when no
 * admin session cookie is present. The real session/cookie handling now lives
 * in {@link module:lib/auth/session}; this module re-exports it so existing
 * `@/lib/auth/guard` imports keep working.
 */

export {
  ADMIN_SESSION_COOKIE,
  getSession,
  type AdminSession,
} from "./session";
