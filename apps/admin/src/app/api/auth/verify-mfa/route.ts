import { NextResponse } from "next/server";
import { z } from "zod";
import { adminVerifyMfa, AuthApiError } from "@/lib/auth/api";
import {
  setSessionCookie,
  getMfaCookie,
  clearMfaCookie,
} from "@/lib/auth/session";

/**
 * POST /api/auth/verify-mfa — EPIC-11.T-007.
 *
 * Completes the second login step. The challenge token comes from the HTTP-only
 * cookie set by `/api/auth/login` (never from the request body), so it stays
 * out of client JS. On a valid TOTP code the backend returns the admin access
 * token, which is written to the HTTP-only session cookie and the challenge
 * cookie is cleared.
 */

const bodySchema = z.object({
  code: z.string().regex(/^\d{6}$/, "Enter the 6-digit code."),
});

export async function POST(request: Request): Promise<NextResponse> {
  const raw: unknown = await request.json().catch(() => null);
  const parsed = bodySchema.safeParse(raw);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Enter the 6-digit code from your authenticator app." },
      { status: 400 },
    );
  }

  const mfaToken = await getMfaCookie();
  if (!mfaToken) {
    return NextResponse.json(
      { error: "Your login session expired. Please sign in again." },
      { status: 440 },
    );
  }

  try {
    const result = await adminVerifyMfa({
      mfa_token: mfaToken,
      code: parsed.data.code,
    });
    await clearMfaCookie();
    await setSessionCookie(result.access, result.session_timeout_minutes);
    return NextResponse.json({ ok: true });
  } catch (error) {
    if (error instanceof AuthApiError) {
      if (error.status === 429) {
        return NextResponse.json(
          { error: "Too many attempts. Please wait and try again." },
          { status: 429 },
        );
      }
      return NextResponse.json(
        {
          error:
            error.body?.message ?? "That code didn't work. Please try again.",
        },
        { status: 401 },
      );
    }
    return NextResponse.json(
      { error: "Unable to verify right now. Please try again." },
      { status: 502 },
    );
  }
}
