"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogOut, UserCircle } from "lucide-react";
import type { AdminRole } from "@/types/enums";
import { Button } from "@/components/ui/button";

/** Human-readable label for each admin role (Admin Portal spec §2.1). */
const ROLE_LABELS: Record<AdminRole, string> = {
  super: "Super Admin",
  ops: "Ops Admin",
  finance: "Finance Admin",
  compliance: "Compliance Admin",
  support: "Support Agent",
};

/**
 * Authenticated topbar — EPIC-11.T-008. Shows the signed-in admin's name, a
 * role badge, and a logout control. Logout POSTs to the server route that
 * revokes the token + clears the HTTP-only cookies, then routes to /login.
 */
export function Topbar({ name, role }: { name: string; role: AdminRole }) {
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);

  async function handleLogout() {
    setLoggingOut(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } catch {
      // Ignore network errors — the cookie clear is best-effort; route anyway.
    }
    router.replace("/login");
    router.refresh();
  }

  return (
    <header className="flex h-16 items-center justify-between border-b border-line bg-card px-s6">
      <div className="font-title text-sm text-muted">Admin Portal</div>
      <div className="flex items-center gap-s4">
        <div className="flex items-center gap-s3">
          <UserCircle size={28} className="text-sage" aria-hidden />
          <div className="flex flex-col leading-tight">
            <span className="font-title text-sm font-semibold text-ink">
              {name}
            </span>
            <span className="rounded-chip text-xs text-sageDk">
              {ROLE_LABELS[role]}
            </span>
          </div>
        </div>
        <Button
          variant="ghost"
          onClick={handleLogout}
          disabled={loggingOut}
          aria-label="Log out"
        >
          <LogOut size={16} aria-hidden />
          <span>{loggingOut ? "Signing out…" : "Log out"}</span>
        </Button>
      </div>
    </header>
  );
}
