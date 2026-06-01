import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth/guard";
import { Sidebar } from "@/components/features/sidebar";
import { Topbar } from "@/components/features/topbar";

/**
 * Authenticated dashboard shell. Auth-guard STUB: no fake session cookie →
 * redirect to /login. Real MFA session handling is EPIC-11.
 */
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();
  if (!session) {
    redirect("/login");
  }

  return (
    <div className="flex h-screen bg-cream">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar />
        <main className="flex-1 overflow-y-auto p-s6">{children}</main>
      </div>
    </div>
  );
}
