import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { NotificationComposer } from "@/components/admin/notification_composer";

/**
 * Notification composer page — EPIC-15.T-010.
 *
 * Super + ops only. This mirrors the backend gate on the notification
 * endpoints (`IsPlatformAdmin` → the `platform` section roles super/ops, in
 * `notifications/views.py`, T-007). The dashboard layout already enforces the
 * authenticated-session guard; this page additionally enforces the *role* guard
 * server-side and renders an access-denied panel for any other role. The
 * interactive compose form (audience, channels, bilingual content with variable
 * chips, schedule, reach+cost preview) lives in the {@link NotificationComposer}
 * client component.
 */

const NOTIFICATION_ROLES = new Set(["super", "ops"]);

export default async function NotificationsPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !NOTIFICATION_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">
          Notifications
        </h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Composing notifications is restricted to ops and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <NotificationComposer />;
}
