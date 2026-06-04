"use client";

import { useState } from "react";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from "@/components/ui/table";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
import {
  fetchNotificationDetail,
  notificationDetailQueryKey,
  type Notification,
  type NotificationFilters,
  type NotificationDelivery,
} from "@/lib/api/notifications";
import { useQuery } from "@tanstack/react-query";

/**
 * Notification history table — EPIC-15.T-012 (Admin Portal spec §4.5.2).
 *
 * Presentational, read-only table of sent/scheduled broadcasts: sent at, title,
 * audience description, channels, sent/delivered/opened counts, status, and the
 * sender. A date filter (created_at window) narrows the list, and each row
 * expands to a detail view that lazily fetches the per-recipient delivery rows
 * (`GET /admin/api/notifications/{id}`). Filter + window state is owned by the
 * page; this component never mutates the ledger. All styling is Notun Din token
 * classes (no hardcoded hex/px).
 */

const COLUMNS = [
  "Sent at",
  "Title",
  "Audience",
  "Channels",
  "Sent",
  "Delivered",
  "Opened",
  "Status",
  "Sender",
  "",
] as const;

export interface NotificationHistoryTableProps {
  notifications: Notification[];
  filters: NotificationFilters;
  onFilterChange: (filters: NotificationFilters) => void;
}

function formatWhen(iso: string | null): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString("en-GB", {
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Human-readable audience description from the audience type + filter. */
export function describeAudience(n: Notification): string {
  switch (n.audience_type) {
    case "all":
      return "All users";
    case "role": {
      const role = n.audience_filter.role;
      return typeof role === "string" ? `Role: ${role}` : "Role";
    }
    case "segment":
      return "Segment";
    case "specific": {
      const ids = n.audience_filter.user_ids;
      const count = Array.isArray(ids) ? ids.length : undefined;
      return count !== undefined
        ? `${count} specific user${count === 1 ? "" : "s"}`
        : "Specific users";
    }
    default:
      return n.audience_type;
  }
}

/** Map a broadcast lifecycle status to a chip tone. */
function statusTone(
  status: string,
): "sage" | "rose" | "butter" | "danger" | "neutral" {
  switch (status) {
    case "sent":
      return "sage";
    case "sending":
      return "butter";
    case "scheduled":
      return "neutral";
    case "draft":
      return "neutral";
    case "failed":
      return "danger";
    default:
      return "neutral";
  }
}

/** Map a per-recipient delivery status to a chip tone. */
function deliveryTone(
  status: string,
): "sage" | "rose" | "butter" | "danger" | "neutral" {
  switch (status) {
    case "opened":
    case "delivered":
      return "sage";
    case "sent":
      return "butter";
    case "queued":
      return "neutral";
    case "failed":
      return "danger";
    default:
      return "neutral";
  }
}

export function NotificationHistoryTable({
  notifications,
  filters,
  onFilterChange,
}: NotificationHistoryTableProps) {
  const setFilter = (key: keyof NotificationFilters, value: string) => {
    onFilterChange({ ...filters, [key]: value || undefined });
  };

  return (
    <div className="space-y-s4">
      <HistoryFilterBar filters={filters} onChange={setFilter} />

      {notifications.length === 0 ? (
        <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
          <CardTitle>No notifications</CardTitle>
          <CardDescription>
            No broadcasts match this date range yet.
          </CardDescription>
        </Card>
      ) : (
        <Table aria-label="Notification history">
          <TableHead>
            <TableRow>
              {COLUMNS.map((c, i) => (
                <TableHeaderCell key={c || `col-${i}`}>{c}</TableHeaderCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {notifications.map((n) => (
              <HistoryRow key={String(n.id)} notification={n} />
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}

function HistoryFilterBar({
  filters,
  onChange,
}: {
  filters: NotificationFilters;
  onChange: (key: keyof NotificationFilters, value: string) => void;
}) {
  const inputClass =
    "rounded-sm border border-line bg-card px-s3 py-s2 text-sm text-ink placeholder:text-muted";
  return (
    <div className="flex flex-wrap items-end gap-s3">
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        From
        <input
          type="date"
          aria-label="Filter from date"
          value={filters.from ?? ""}
          onChange={(e) => onChange("from", e.target.value)}
          className={inputClass}
        />
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        To
        <input
          type="date"
          aria-label="Filter to date"
          value={filters.to ?? ""}
          onChange={(e) => onChange("to", e.target.value)}
          className={inputClass}
        />
      </label>
    </div>
  );
}

function HistoryRow({ notification }: { notification: Notification }) {
  const [open, setOpen] = useState(false);
  const title = notification.title_en || notification.title_bn || "—";

  return (
    <>
      <TableRow>
        <TableCell className="whitespace-nowrap">
          {formatWhen(notification.scheduled_at ?? notification.created_at)}
        </TableCell>
        <TableCell className="font-semibold">{title}</TableCell>
        <TableCell>{describeAudience(notification)}</TableCell>
        <TableCell className="font-mono text-xs">
          {notification.channels.join(", ") || "—"}
        </TableCell>
        <TableCell>{notification.sent_count}</TableCell>
        <TableCell>{notification.delivered_count}</TableCell>
        <TableCell>{notification.opened_count}</TableCell>
        <TableCell>
          <Chip tone={statusTone(notification.status)}>
            {notification.status}
          </Chip>
        </TableCell>
        <TableCell>
          {notification.sender === null ? "System" : String(notification.sender)}
        </TableCell>
        <TableCell className="text-right">
          <button
            type="button"
            aria-expanded={open}
            aria-label={open ? "Hide deliveries" : "Show deliveries"}
            onClick={() => setOpen((v) => !v)}
            className="rounded-button border border-line px-s3 py-s1 font-title text-xs font-semibold text-ink"
          >
            {open ? "Hide" : "Detail"}
          </button>
        </TableCell>
      </TableRow>
      {open ? (
        <TableRow>
          <TableCell colSpan={COLUMNS.length} className="bg-sageBg">
            <DeliveriesDetail id={notification.id} />
          </TableCell>
        </TableRow>
      ) : null}
    </>
  );
}

function DeliveriesDetail({ id }: { id: Notification["id"] }) {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: notificationDetailQueryKey(id),
    queryFn: () => fetchNotificationDetail(id),
  });

  if (isPending) {
    return (
      <div
        className="h-24 animate-pulse rounded-sm bg-card"
        aria-busy
        aria-label="Loading deliveries"
      />
    );
  }

  if (isError) {
    return (
      <div className="flex flex-col items-start gap-s2">
        <p className="text-sm text-mutedDk">
          Could not load per-recipient deliveries.
        </p>
        <button
          type="button"
          onClick={() => void refetch()}
          className="rounded-button border border-line px-s3 py-s1 font-title text-xs font-semibold text-ink"
        >
          Retry
        </button>
      </div>
    );
  }

  if (data.deliveries.length === 0) {
    return (
      <p className="text-sm text-mutedDk">No per-recipient deliveries yet.</p>
    );
  }

  return (
    <div>
      <p className="mb-s2 font-title text-xs font-semibold uppercase tracking-wide text-mutedDk">
        Per-recipient deliveries ({data.deliveries.length})
      </p>
      <Table aria-label="Per-recipient deliveries">
        <TableHead>
          <TableRow>
            <TableHeaderCell>Recipient</TableHeaderCell>
            <TableHeaderCell>Channel</TableHeaderCell>
            <TableHeaderCell>Status</TableHeaderCell>
            <TableHeaderCell>Delivered</TableHeaderCell>
            <TableHeaderCell>Opened</TableHeaderCell>
            <TableHeaderCell>Error</TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {data.deliveries.map((d) => (
            <DeliveryRow key={String(d.id)} delivery={d} />
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

function DeliveryRow({ delivery }: { delivery: NotificationDelivery }) {
  return (
    <TableRow>
      <TableCell>{delivery.user === null ? "—" : String(delivery.user)}</TableCell>
      <TableCell className="font-mono text-xs">{delivery.channel}</TableCell>
      <TableCell>
        <Chip tone={deliveryTone(delivery.status)}>{delivery.status}</Chip>
      </TableCell>
      <TableCell className="whitespace-nowrap">
        {formatWhen(delivery.delivered_at)}
      </TableCell>
      <TableCell className="whitespace-nowrap">
        {formatWhen(delivery.opened_at)}
      </TableCell>
      <TableCell className="text-danger">{delivery.error ?? "—"}</TableCell>
    </TableRow>
  );
}
