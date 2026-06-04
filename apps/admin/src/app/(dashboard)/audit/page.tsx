"use client";

import { useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { AuditTable } from "@/components/admin/audit_table";
import {
  auditQueryKey,
  fetchAuditLog,
  type AuditFilters,
} from "@/lib/api/audit";

/**
 * Audit-log viewer — EPIC-11.T-011.
 *
 * Compliance-facing, read-only viewer over the immutable `AdminAuditEntry`
 * ledger. Fetches `GET /admin/api/audit-log` via TanStack Query with the active
 * filter set; the page owns filter + cursor state and threads them into the
 * presentational {@link AuditTable}. Cursor pagination keeps the previous page
 * visible while the next loads (`keepPreviousData`). Styling is Notun Din tokens.
 */

/** Extract the opaque cursor value from a DRF cursor-pagination link. */
function cursorFromLink(link: string | null): string | undefined {
  if (!link) return undefined;
  try {
    return new URL(link).searchParams.get("cursor") ?? undefined;
  } catch {
    return undefined;
  }
}

export default function AuditPage() {
  const [filters, setFilters] = useState<AuditFilters>({});

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: auditQueryKey(filters),
    queryFn: () => fetchAuditLog(filters),
    placeholderData: keepPreviousData,
  });

  const nextCursor = cursorFromLink(data?.pagination.next ?? null);
  const prevCursor = cursorFromLink(data?.pagination.previous ?? null);

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Audit log</h1>
        <p className="mt-s1 text-sm text-muted">
          Immutable record of every admin action — who, what, when, before and
          after. Read-only.
        </p>
      </div>

      {isPending ? (
        <Card className="h-64 animate-pulse" aria-busy aria-label="Loading audit log" />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load the audit log</CardTitle>
          <CardDescription>
            The audit-log request failed. Check your connection and try again.
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
        <AuditTable
          entries={data.results}
          filters={filters}
          onFilterChange={setFilters}
          hasNext={Boolean(nextCursor)}
          hasPrevious={Boolean(prevCursor)}
          onNext={() =>
            setFilters((f) => ({ ...f, cursor: nextCursor }))
          }
          onPrevious={() =>
            setFilters((f) => ({ ...f, cursor: prevCursor }))
          }
        />
      )}
    </div>
  );
}
