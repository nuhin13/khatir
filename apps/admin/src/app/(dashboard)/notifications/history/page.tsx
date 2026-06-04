import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { NotificationHistoryClient } from "./history_client";

/**
 * Notification history page — EPIC-15.T-012 (Admin Portal spec §4.5.2).
 *
 * Super + ops only. Mirrors the backend gate on the notification endpoints
 * (`IsPlatformAdmin` → the `platform` section roles super/ops, in
 * `notifications/views.py`, T-007). The dashboard layout already enforces the
 * authenticated-session guard; this page additionally enforces the *role* guard
 * server-side and renders an access-denied panel for any other role. The
 * interactive table (date filter, per-broadcast counts, per-recipient delivery
 * detail) lives in the {@link NotificationHistoryClient} client component.
 */

const NOTIFICATION_ROLES = new Set(["super", "ops"]);

export default async function NotificationHistoryPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !NOTIFICATION_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">
          Notification history
        </h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Notification history is restricted to ops and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <NotificationHistoryClient />;
}
