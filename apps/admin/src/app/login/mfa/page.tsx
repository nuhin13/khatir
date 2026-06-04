"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";

/**
 * Admin login — step two (6-digit TOTP) — EPIC-11.T-007.
 *
 * Posts the code to the server-side `/api/auth/verify-mfa` route handler. The
 * MFA challenge token is read from its HTTP-only cookie server-side, so it is
 * never exposed here. On success the session cookie is set and we redirect to
 * the dashboard; an expired challenge sends the user back to `/login`.
 */
export default function MfaPage() {
  const router = useRouter();
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const response = await fetch("/api/auth/verify-mfa", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code }),
      });
      const data: unknown = await response.json().catch(() => null);

      if (!response.ok) {
        const message =
          (data as { error?: string } | null)?.error ??
          "That code didn't work. Please try again.";
        setError(message);
        setCode("");
        if (response.status === 440) {
          // Challenge expired — restart the flow.
          router.push("/login");
        }
        return;
      }

      router.push("/dashboard");
      router.refresh();
    } catch {
      setError("Unable to verify right now. Please try again.");
      setCode("");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-cream p-s5">
      <Card className="w-full max-w-sm">
        <div className="mb-s5 text-center">
          <p className="font-title text-xl font-bold text-ink">
            Two-factor authentication
          </p>
          <CardDescription>
            Enter the 6-digit code from your authenticator app
          </CardDescription>
        </div>

        <CardTitle className="sr-only">MFA challenge</CardTitle>

        <form className="space-y-s4" onSubmit={onSubmit} noValidate>
          <label className="block">
            <span className="mb-s1 block font-title text-sm text-ink2">
              Authentication code
            </span>
            <input
              type="text"
              name="code"
              inputMode="numeric"
              autoComplete="one-time-code"
              required
              maxLength={6}
              pattern="\d{6}"
              aria-label="6-digit authentication code"
              value={code}
              onChange={(e) =>
                setCode(e.target.value.replace(/\D/g, "").slice(0, 6))
              }
              placeholder="123456"
              className="w-full rounded-sm border border-line bg-cream px-s3 py-s3 text-center font-title text-lg tracking-[0.5em] text-ink outline-none focus:border-sage"
            />
          </label>

          {error ? (
            <p role="alert" className="text-sm text-danger">
              {error}
            </p>
          ) : null}

          <Button
            type="submit"
            className="w-full"
            disabled={loading || code.length !== 6}
          >
            {loading ? "Verifying…" : "Verify"}
          </Button>
        </form>
      </Card>
    </main>
  );
}
