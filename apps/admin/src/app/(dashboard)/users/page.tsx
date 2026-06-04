import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { UsersBrowser } from "@/components/admin/users_browser";

/**
 * Users list + search page — EPIC-12.T-007.
 *
 * Ops + support + super only (Admin Portal spec §2.1: the `users` section is
 * read-accessible to ops/support; super is allowed everywhere). The dashboard
 * layout already enforces the authenticated-session guard; this page
 * additionally enforces the *role* guard server-side — mirroring the backend
 * `IsUsersReadAdmin` gate (admin_portal/user_views.py, T-003) — and renders an
 * access-denied panel for any other role rather than the browser. The
 * interactive search + paginated table lives in the {@link UsersBrowser} client
 * island.
 */

const USERS_READ_ROLES = new Set(["super", "ops", "support"]);

export default async function UsersPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !USERS_READ_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Users</h1>
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

  return <UsersBrowser />;
}
