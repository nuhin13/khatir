"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";

/**
 * Admin login — step one (email + password) — EPIC-11.T-007.
 *
 * Posts to the server-side `/api/auth/login` route handler, which talks to the
 * backend and sets the HTTP-only session/MFA cookie. The admin token never
 * touches client JS. On an MFA challenge the user is routed to `/login/mfa`;
 * otherwise the session is already set and we go straight to the dashboard.
 */
export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    const form = new FormData(event.currentTarget);
    const email = String(form.get("email") ?? "");
    const password = String(form.get("password") ?? "");

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data: unknown = await response.json().catch(() => null);

      if (!response.ok) {
        const message =
          (data as { error?: string } | null)?.error ?? "Invalid credentials.";
        setError(message);
        return;
      }

      if ((data as { mfa_required?: boolean }).mfa_required) {
        router.push("/login/mfa");
        return;
      }

      router.push("/dashboard");
      router.refresh();
    } catch {
      setError("Unable to sign in right now. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-cream p-s5">
      <Card className="w-full max-w-sm">
        <div className="mb-s5 text-center">
          <p className="font-title text-xl font-bold text-ink">Khatir Admin</p>
          <CardDescription>Sign in to the admin portal</CardDescription>
        </div>

        <CardTitle className="sr-only">Login</CardTitle>

        <form className="space-y-s4" onSubmit={onSubmit} noValidate>
          <label className="block">
            <span className="mb-s1 block font-title text-sm text-ink2">
              Email
            </span>
            <input
              type="email"
              name="email"
              autoComplete="email"
              required
              placeholder="you@khatir.com.bd"
              className="w-full rounded-sm border border-line bg-cream px-s3 py-s3 text-sm text-ink outline-none focus:border-sage"
            />
          </label>

          <label className="block">
            <span className="mb-s1 block font-title text-sm text-ink2">
              Password
            </span>
            <input
              type="password"
              name="password"
              autoComplete="current-password"
              required
              placeholder="••••••••"
              className="w-full rounded-sm border border-line bg-cream px-s3 py-s3 text-sm text-ink outline-none focus:border-sage"
            />
          </label>

          {error ? (
            <p role="alert" className="text-sm text-danger">
              {error}
            </p>
          ) : null}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </Card>
    </main>
  );
}
