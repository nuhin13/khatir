import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { PricingEditor } from "@/components/admin/pricing_editor";

/**
 * Pricing editor page — EPIC-12.T-005.
 *
 * Finance + super only (Admin Portal spec §2.1: pricing is finance-owned;
 * super is allowed everywhere). The dashboard layout already enforces the
 * authenticated-session guard; this page additionally enforces the *role*
 * guard server-side — mirroring the backend `IsPricingAdmin` gate
 * (admin_portal/pricing_views.py, T-001) — and renders an access-denied panel
 * for any other role rather than the editor. The interactive editor (tier
 * table, preview, reason + confirm) lives in the {@link PricingEditor} client
 * component.
 */

const PRICING_ROLES = new Set(["super", "finance"]);

export default async function PricingPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !PRICING_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Pricing</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Pricing configuration is restricted to finance and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <PricingEditor />;
}
