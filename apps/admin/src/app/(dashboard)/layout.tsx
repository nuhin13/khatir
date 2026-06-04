import { redirect } from "next/navigation";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { Sidebar } from "@/components/features/sidebar";
import { Topbar } from "@/components/features/topbar";
import { SessionTimeoutWarning } from "@/components/features/session-timeout-warning";

/**
 * Authenticated dashboard shell — EPIC-11.T-008.
 *
 * Real session guard (replaces the EPIC-00 stub): resolves the authenticated
 * admin server-side via {@link getAuthenticatedAdmin} (cookie → backend `/me`).
 * No valid session → redirect to /login. The resolved role drives the
 * role-aware sidebar, the name/role drive the topbar, and the token expiry
 * drives the client-side session-timeout warning.
 */
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const admin = await getAuthenticatedAdmin();
  if (!admin) {
    redirect("/login");
  }

  return (
    <div className="flex h-screen bg-cream">
      <Sidebar role={admin.role} />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar name={admin.name} role={admin.role} />
        <SessionTimeoutWarning expiresAt={admin.expiresAt} />
        <main className="flex-1 overflow-y-auto p-s6">{children}</main>
      </div>
    </div>
  );
}
