import { NextResponse } from "next/server";
import { adminLogout } from "@/lib/auth/api";
import {
  getSession,
  clearSessionCookie,
  clearMfaCookie,
} from "@/lib/auth/session";

/**
 * POST /api/auth/logout — EPIC-11.T-007.
 *
 * Revokes the admin token on the backend (best-effort) and clears the local
 * HTTP-only session + MFA cookies.
 */
export async function POST(): Promise<NextResponse> {
  const session = await getSession();
  if (session) {
    await adminLogout(session.token);
  }
  await clearSessionCookie();
  await clearMfaCookie();
  return NextResponse.json({ ok: true });
}
