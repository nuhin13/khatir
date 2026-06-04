"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { KpiCard } from "@/components/admin/kpi_card";
import { ActivityFeed } from "@/components/admin/activity_feed";
import { HealthTile } from "@/components/admin/health_tile";
import {
  dashboardQueryKey,
  fetchDashboard,
  type Dashboard,
} from "@/lib/api/dashboard";

/**
 * Platform dashboard — EPIC-11.T-009.
 *
 * Replaces the EPIC-00 placeholder. Fetches `GET /admin/api/dashboard` via
 * TanStack Query, auto-refreshing every 60s (task §2). Renders KPI tiles, the
 * recent-activity feed, and the system-health panel, with loading / error /
 * data states. All styling comes from Notun Din token classes.
 */

const REFETCH_MS = 60_000;

function formatTaka(amount: string): string {
  const n = Number(amount);
  if (Number.isNaN(n)) return `৳${amount}`;
  return `৳${n.toLocaleString("en-BD", { maximumFractionDigits: 0 })}`;
}

function kpiTiles(data: Dashboard) {
  return [
    { label: "Total users", value: data.total_users.toLocaleString() },
    {
      label: "Active landlords",
      value: data.active_landlords.toLocaleString(),
    },
    {
      label: "Properties",
      value: data.total_properties.toLocaleString(),
      hint: `${data.occupied_units.toLocaleString()} / ${data.total_units.toLocaleString()} units occupied`,
    },
    {
      label: "Rent collected (this month)",
      value: formatTaka(data.total_rent_collected.this_month),
      hint: `${formatTaka(data.total_rent_collected.all_time)} all time`,
    },
    {
      label: "DMP forms generated",
      value: data.dmp_forms_generated.toLocaleString(),
    },
    {
      label: "Active subscriptions",
      value: data.active_subscriptions.toLocaleString(),
    },
  ];
}

export default function DashboardPage() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: dashboardQueryKey,
    queryFn: fetchDashboard,
    refetchInterval: REFETCH_MS,
  });

  return (
    <div className="space-y-s6">
      <h1 className="font-title text-2xl font-bold text-ink">Dashboard</h1>

      {isPending ? (
        <DashboardSkeleton />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load dashboard</CardTitle>
          <CardDescription>
            The platform metrics request failed. Check your connection and try
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
        <>
          <section className="grid grid-cols-1 gap-s4 sm:grid-cols-2 lg:grid-cols-3">
            {kpiTiles(data).map((kpi) => (
              <KpiCard key={kpi.label} {...kpi} />
            ))}
          </section>

          <section className="grid grid-cols-1 gap-s4 lg:grid-cols-3">
            <div className="lg:col-span-2">
              <ActivityFeed entries={data.recent_activity} />
            </div>
            <div>
              <HealthTile health={data.health} />
            </div>
          </section>
        </>
      )}
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="space-y-s6" aria-busy aria-label="Loading dashboard">
      <section className="grid grid-cols-1 gap-s4 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <Card key={i} className="animate-pulse">
            <div className="h-s3 w-1/2 rounded-xs bg-line" />
            <div className="mt-s3 h-s7 w-2/3 rounded-xs bg-line" />
          </Card>
        ))}
      </section>
      <Card className="h-48 animate-pulse" />
    </div>
  );
}
