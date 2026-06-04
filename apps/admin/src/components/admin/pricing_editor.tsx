"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { TierTable } from "@/components/admin/tier_table";
import {
  fetchPricingTiers,
  pricingTiersQueryKey,
} from "@/lib/api/pricing";

/**
 * Pricing editor client surface — EPIC-12.T-005.
 *
 * Fetches every pricing tier via TanStack Query (`GET /admin/api/pricing/tiers`,
 * T-001) and feeds them to the editable {@link TierTable}. Owns the loading and
 * error states; the table owns inline edit, preview, reason + confirm, and the
 * post-apply refetch. The finance+super route guard lives in the server page
 * that renders this component.
 */
export function PricingEditor() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: pricingTiersQueryKey,
    queryFn: fetchPricingTiers,
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Pricing</h1>
        <p className="mt-s1 text-sm text-muted">
          Edit tier breakpoints and prices without a code deploy. Changes take
          effect within 60 seconds and are fully audit-logged with a before /
          after diff.
        </p>
      </div>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading pricing tiers"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load pricing tiers</CardTitle>
          <CardDescription>
            The pricing-tier request failed. Check your connection and try
            again.
          </CardDescription>
          <button
            type="button"
            onClick={() => void refetch()}
            className="mt-s2 rounded-button bg-ink px-s5 py-s2 font-title text-sm font-semibold text-card"
          >
            Retry
          </button>
        </Card>
      ) : (
        <TierTable tiers={data} />
      )}
    </div>
  );
}
