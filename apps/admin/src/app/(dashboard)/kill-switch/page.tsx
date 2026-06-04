import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { KillSwitchPanel } from "@/components/admin/killswitch_panel";

/**
 * Emergency kill-switch page — EPIC-13.T-006.
 *
 * **Super only.** This mirrors the backend gate on the kill-switch endpoints
 * (`IsSuperAdmin` in `featureflags/killswitch_views.py`, T-003): only the
 * `super` admin role may list or throw a kill-switch. The dashboard layout
 * already enforces the authenticated-session guard; this page additionally
 * enforces the *role* guard server-side and renders an access-denied panel for
 * any other role rather than the panel. The interactive switch list, red
 * warning banner, and friction-heavy MFA confirm dialog live in the
 * {@link KillSwitchPanel} client component.
 */
export default async function KillSwitchPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || admin.role !== "super") {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Kill-switch</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            The emergency kill-switch panel is restricted to super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <KillSwitchPanel />;
}
