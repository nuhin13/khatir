import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { ConsentRecordsClient } from "./consent_client";

/**
 * Consent-records page — EPIC-16.T-007.
 *
 * **Compliance + super only.** This mirrors the backend gate on the compliance
 * endpoints (`IsComplianceAdmin` = super / compliance in `compliance/views.py`,
 * EPIC-16.T-003): only those roles may read the consent log. The dashboard
 * layout already enforces the authenticated-session guard; this page
 * additionally enforces the *role* guard server-side and renders an
 * access-denied panel for any other role rather than the viewer. The
 * interactive filter bar and read-only table live in the
 * {@link ConsentRecordsClient} client component.
 */
export default async function ComplianceConsentPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || (admin.role !== "compliance" && admin.role !== "super")) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">
          Consent records
        </h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Consent records are restricted to compliance and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <ConsentRecordsClient />;
}
