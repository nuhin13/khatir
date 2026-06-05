import { NextResponse } from "next/server";
import { z } from "zod";
import { adminLogin, AuthApiError } from "@/lib/auth/api";
import {
  setSessionCookie,
  setMfaCookie,
  clearMfaCookie,
} from "@/lib/auth/session";

/**
 * POST /api/auth/login — EPIC-11.T-007.
 *
 * Server-side proxy for the admin login step. The browser posts credentials
 * here; this handler calls the backend and either:
 *   - returns `{ mfa_required: true }` and stores the challenge token in an
 *     HTTP-only cookie for `/login/mfa`, or
 *   - completes login by writing the admin access token into the HTTP-only
 *     session cookie and returning `{ mfa_required: false }`.
 * The access/challenge tokens never reach client-readable JS.
 */

const bodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export async function POST(request: Request): Promise<NextResponse> {
  const raw: unknown = await request.json().catch(() => null);
  const parsed = bodySchema.safeParse(raw);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Please enter a valid email and password." },
      { status: 400 },
    );
  }

  try {
    const result = await adminLogin(parsed.data);

    if (result.mfa_required) {
      await setMfaCookie(result.mfa_token);
      return NextResponse.json({ mfa_required: true });
    }

    // No MFA configured for this account — session is complete.
    await clearMfaCookie();
    await setSessionCookie(result.access, result.session_timeout_minutes);
    return NextResponse.json({ mfa_required: false });
  } catch (error) {
    if (error instanceof AuthApiError) {
      const status = error.status === 429 ? 429 : 401;
      const message =
        status === 429
          ? "Too many attempts. Please wait and try again."
          : (error.body?.message ?? "Invalid credentials.");
      return NextResponse.json({ error: message }, { status });
    }
    return NextResponse.json(
      { error: "Unable to sign in right now. Please try again." },
      { status: 502 },
    );
  }
}
