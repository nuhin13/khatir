import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { NotificationTemplates } from "@/components/admin/notification_templates";

/**
 * Notification templates page — EPIC-15.T-013.
 *
 * Super + ops only. This mirrors the backend gate on the template endpoints
 * (`IsPlatformAdmin` → the `platform` section roles super/ops, in
 * `notifications/views.py` `NotificationTemplateViewSet`, T-008). The dashboard
 * layout already enforces the authenticated-session guard; this page
 * additionally enforces the *role* guard server-side and renders an
 * access-denied panel for any other role. The interactive list + per-template
 * editor (bilingual title/body, channels, active, with the variable reference
 * and the immutable trigger event shown read-only) lives in the
 * {@link NotificationTemplates} client component.
 */

const NOTIFICATION_ROLES = new Set(["super", "ops"]);

export default async function NotificationTemplatesPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !NOTIFICATION_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">
          Notification templates
        </h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Editing notification templates is restricted to ops and super
            admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <NotificationTemplates />;
}
