"use client";

import { useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { ConsentTable } from "@/components/admin/consent_table";
import {
  consentQueryKey,
  fetchConsentRecords,
  pageFromLink,
  type ConsentFilters,
} from "@/lib/api/consent";

/**
 * Consent-records viewer client — EPIC-16.T-007.
 *
 * Compliance-facing, read-only viewer over the append-only `ConsentRecord` log
 * (EPIC-16.T-003). Fetches `GET /admin/api/consent-records` via TanStack Query
 * with the active filter set; the component owns filter + page state and
 * threads them into the presentational {@link ConsentTable} (user/consent-type/
 * date filters). Page-number pagination keeps the previous page visible while
 * the next loads (`keepPreviousData`). Styling is Notun Din tokens — no
 * hardcoded hex/px.
 *
 * The route's compliance+super role guard lives in the server `page.tsx`; this
 * component assumes it has already passed.
 */
export function ConsentRecordsClient() {
  const [filters, setFilters] = useState<ConsentFilters>({});

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: consentQueryKey(filters),
    queryFn: () => fetchConsentRecords(filters),
    placeholderData: keepPreviousData,
  });

  const nextPage = pageFromLink(data?.pagination.next ?? null);
  const prevPage = pageFromLink(data?.pagination.previous ?? null);

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">
          Consent records
        </h1>
        <p className="mt-s1 text-sm text-muted">
          Logged consent events — who consented to what, and when it was granted,
          revoked, or expires. Read-only.
        </p>
      </div>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading consent records"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load consent records</CardTitle>
          <CardDescription>
            The consent-records request failed. Check your connection and try
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
        <ConsentTable
          records={data.results}
          filters={filters}
          onFilterChange={setFilters}
          hasNext={Boolean(nextPage)}
          hasPrevious={Boolean(prevPage)}
          onNext={() => setFilters((f) => ({ ...f, page: nextPage }))}
          onPrevious={() => setFilters((f) => ({ ...f, page: prevPage }))}
        />
      )}
    </div>
  );
}
