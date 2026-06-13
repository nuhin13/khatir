import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { RefundQueue } from "@/components/admin/refund_queue";

/**
 * Refund queue page — EPIC-12.T-009.
 *
 * Finance staff review pending refund requests and approve / deny each one. The
 * dashboard layout already enforces the authenticated-session guard; this page
 * additionally enforces the *role* guard server-side — mirroring the backend
 * `IsBillingAdmin` gate (admin_portal/refund_views.py, T-004): only `finance`
 * and `super` may view or act. Any other role gets an access-denied panel
 * rather than the queue island.
 */

const REFUND_ROLES = new Set(["super", "finance"]);

export default async function RefundsPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !REFUND_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">Refunds</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            The refund queue is restricted to finance and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <RefundQueue />;
}
