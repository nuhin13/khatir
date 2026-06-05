"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Clock } from "lucide-react";
import { Button } from "@/components/ui/button";

/** Show the warning when this many seconds (or fewer) remain before expiry. */
const WARN_BEFORE_SECONDS = 5 * 60;
/** How often to re-check the remaining session lifetime. */
const TICK_MS = 15_000;

function formatRemaining(seconds: number): string {
  const safe = Math.max(0, seconds);
  const mins = Math.floor(safe / 60);
  const secs = safe % 60;
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}

/**
 * Session-timeout warning — EPIC-11.T-008.
 *
 * Driven by the JWT `exp` (seconds) resolved server-side. When the session is
 * within {@link WARN_BEFORE_SECONDS} of expiry, a banner appears with the
 * countdown. The admin can "Stay signed in" (re-validates the session against
 * the backend `/me` via a server refresh — if the token is still live the
 * banner clears, otherwise the layout guard redirects to /login). Once the
 * token has actually expired, the admin is sent to /login.
 */
export function SessionTimeoutWarning({
  expiresAt,
}: {
  expiresAt: number | null;
}) {
  const router = useRouter();
  // `nowSeconds` is bumped only inside the interval callback (never
  // synchronously in an effect body), so the remaining time is derived during
  // render from props + this ticking clock.
  const [nowSeconds, setNowSeconds] = useState(() =>
    Math.floor(Date.now() / 1000),
  );

  useEffect(() => {
    if (expiresAt === null) return;
    const id = setInterval(() => {
      setNowSeconds(Math.floor(Date.now() / 1000));
    }, TICK_MS);
    return () => clearInterval(id);
  }, [expiresAt]);

  const remaining = expiresAt === null ? null : expiresAt - nowSeconds;

  // Expired → bounce to login (the server guard would do the same on next nav).
  useEffect(() => {
    if (remaining !== null && remaining <= 0) {
      router.replace("/login");
      router.refresh();
    }
  }, [remaining, router]);

  if (
    remaining === null ||
    remaining <= 0 ||
    remaining > WARN_BEFORE_SECONDS
  ) {
    return null;
  }

  return (
    <div
      role="alert"
      className="flex items-center justify-between gap-s4 border-b border-line bg-butterBg px-s6 py-s3"
    >
      <div className="flex items-center gap-s3 text-sm text-butterDk">
        <Clock size={16} aria-hidden />
        <span className="font-title font-semibold">
          Your session expires in {formatRemaining(remaining)}.
        </span>
      </div>
      <Button
        variant="secondary"
        onClick={() => router.refresh()}
        aria-label="Stay signed in"
      >
        Stay signed in
      </Button>
    </div>
  );
}
