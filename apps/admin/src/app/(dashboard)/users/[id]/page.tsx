import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { UserDetail } from "@/components/admin/user_detail";

/**
 * User detail + actions page — EPIC-12.T-008.
 *
 * Full user profile with subscription, usage, audit trail, and action buttons
 * (suspend / reactivate / manual upgrade). The dashboard layout already enforces
 * the authenticated-session guard; this page additionally enforces the *role*
 * guard server-side — mirroring the backend `IsUsersReadAdmin` gate
 * (admin_portal/user_views.py, T-003) — and renders an access-denied panel for
 * any other role rather than the detail island.
 *
 * Read access is ops + support + super; the write actions (suspend / reactivate
 * / upgrade) are ops + super only (`IsUsersWriteAdmin`). Support therefore sees
 * the profile but no action buttons — the {@link UserDetail} island is told
 * whether the viewer may act via `canWrite`.
 */

const USERS_READ_ROLES = new Set(["super", "ops", "support"]);
const USERS_WRITE_ROLES = new Set(["super", "ops"]);

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const admin = await getAuthenticatedAdmin();

  if (!admin || !USERS_READ_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">User detail</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            User management is restricted to operations, support, and super
            admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-s6">
      <Link
        href="/users"
        className="inline-flex items-center gap-s2 text-sm font-semibold text-muted hover:text-ink"
      >
        <ArrowLeft size={15} aria-hidden />
        Back to users
      </Link>
      <UserDetail id={id} canWrite={USERS_WRITE_ROLES.has(admin.role)} />
    </div>
  );
}
