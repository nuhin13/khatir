import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { AuditLogClient } from "./audit_client";

/**
 * Enhanced audit-log page — EPIC-16.T-006 (replaces EPIC-11.T-011).
 *
 * **Compliance + super only.** This mirrors the backend gate on the compliance
 * endpoints (`SECTION_ROLES[AdminSection.AUDIT]` = super / compliance in
 * `compliance/views.py`, EPIC-16.T-002): only those roles may read the audit
 * ledger or pull the CSV export. The dashboard layout already enforces the
 * authenticated-session guard; this page additionally enforces the *role* guard
 * server-side and renders an access-denied panel for any other role rather than
 * the viewer. The interactive filter bar, before/after diff, cursor pagination,
 * and CSV-export button live in the {@link AuditLogClient} client component.
 */
export default async function ComplianceAuditPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || (admin.role !== "compliance" && admin.role !== "super")) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Audit log</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            The audit log is restricted to compliance and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <AuditLogClient />;
}
