import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { getAuthenticatedAdmin } from "@/lib/auth/admin-session";
import { AIProvidersPanel } from "@/components/admin/ai_providers_panel";

/**
 * AI-providers configuration page — EPIC-14.T-011.
 *
 * Super + ops only. This mirrors the backend gate on the AI-provider endpoints
 * (`IsAIProviderAdmin` → the `platform` section roles super/ops, in
 * `ai_providers/admin_views.py`, T-009). The dashboard layout already enforces
 * the authenticated-session guard; this page additionally enforces the *role*
 * guard server-side and renders an access-denied panel for any other role. The
 * interactive 4-tab provider editor + test-connection + DPA warning lives in the
 * {@link AIProvidersPanel} client component.
 */

const AI_ROLES = new Set(["super", "ops"]);

export default async function AIProvidersPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin || !AI_ROLES.has(admin.role)) {
    return (
      <div className="space-y-s5">
        <h1 className="font-title text-2xl font-bold text-ink">AI providers</h1>
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Access denied</CardTitle>
          <CardDescription>
            AI-provider configuration is restricted to ops and super admins.
          </CardDescription>
        </Card>
      </div>
    );
  }

  return <AIProvidersPanel />;
}
