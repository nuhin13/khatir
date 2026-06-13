import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { DataRequestsClient } from "./requests_client";

/**
 * Data-requests page — EPIC-16.T-008.
 *
 * **Compliance + super only.** This mirrors the backend gate on the
 * data-request endpoints (`IsComplianceAdmin` = super / compliance in
 * `compliance/data_request_views.py`, EPIC-16.T-004): only those roles may view
 * the PDPA export/erasure queue or process a request. The dashboard layout
 * already enforces the authenticated-session guard; this page additionally
 * enforces the *role* guard server-side and renders an access-denied panel for
 * any other role rather than the queue. The interactive pending queue (SLA
 * badges + approve/reject dialog) and completed history tab live in the
 * {@link DataRequestsClient} client component.
 */
export default async function ComplianceRequestsPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || (admin.role !== "compliance" && admin.role !== "super")) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Data requests</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            Data requests are restricted to compliance and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <DataRequestsClient />;
}
