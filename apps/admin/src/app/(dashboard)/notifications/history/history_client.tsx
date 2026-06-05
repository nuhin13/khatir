"use client";

import { useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { NotificationHistoryTable } from "@/components/admin/notification_history_table";
import {
  fetchNotifications,
  notificationsQueryKey,
  type NotificationFilters,
} from "@/lib/api/notifications";

/**
 * Notification history client — EPIC-15.T-012.
 *
 * Owns the date-filter state and fetches `GET /admin/api/notifications` (newest
 * first) via TanStack Query, threading the filters into the presentational
 * {@link NotificationHistoryTable}. Renders loading / error / data states; the
 * previous page stays visible while a filtered re-query loads
 * (`keepPreviousData`). Styling is Notun Din tokens.
 */
export function NotificationHistoryClient() {
  const [filters, setFilters] = useState<NotificationFilters>({});

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: notificationsQueryKey(filters),
    queryFn: () => fetchNotifications(filters),
    placeholderData: keepPreviousData,
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">
          Notification history
        </h1>
        <p className="mt-s1 text-sm text-muted">
          Every sent and scheduled broadcast — reach, delivery and open counts,
          status, and per-recipient delivery detail. Read-only.
        </p>
      </div>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading notification history"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load notification history</CardTitle>
          <CardDescription>
            The notifications request failed. Check your connection and try
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
        <NotificationHistoryTable
          notifications={data}
          filters={filters}
          onFilterChange={setFilters}
        />
      )}
    </div>
  );
}
