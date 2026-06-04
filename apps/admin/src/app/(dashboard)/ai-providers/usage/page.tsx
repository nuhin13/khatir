import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { AIUsagePanel } from "@/components/admin/ai_usage_panel";

/**
 * AI-usage panel page — EPIC-14.T-012.
 *
 * Super + ops only. This mirrors the backend gate on the AI-provider /
 * AI-usage endpoints (`IsAIProviderAdmin` → the `platform` section roles
 * super/ops, in `ai_providers/admin_views.py`, T-009). The dashboard layout
 * already enforces the authenticated-session guard; this page additionally
 * enforces the *role* guard server-side and renders an access-denied panel for
 * any other role. The interactive usage table + cost totals + failover/error
 * log + date filter lives in the {@link AIUsagePanel} client component, which
 * consumes `GET /admin/api/ai-usage`.
 */

const AI_ROLES = new Set(["super", "ops"]);

export default async function AIUsagePage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !AI_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">AI usage</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            AI usage is restricted to ops and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <AIUsagePanel />;
}
