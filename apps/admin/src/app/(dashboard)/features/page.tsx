import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { FlagsConsole } from "@/components/admin/flags_console";

/**
 * Feature-flags console page — EPIC-13.T-005.
 *
 * Super + ops only. This mirrors the backend gate on the flag endpoints
 * (`IsPlatformAdmin` → the `platform` section roles super/ops, in
 * `featureflags/views.py`, T-002). The dashboard layout already enforces the
 * authenticated-session guard; this page additionally enforces the *role* guard
 * server-side and renders an access-denied panel for any other role rather than
 * the console. The interactive flag table + toggle + confirm dialog lives in the
 * {@link FlagsConsole} client component.
 */

const FLAG_ROLES = new Set(["super", "ops"]);

export default async function FeaturesPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !FLAG_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Features</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Feature-flag management is restricted to ops and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <FlagsConsole />;
}
