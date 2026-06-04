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
import type { AuditEntry, AuditFilters } from "@/lib/api/audit";

/**
 * Audit-log table — EPIC-11.T-011.
 *
 * Renders the filter bar, the paginated table of immutable audit entries, and a
 * per-row before/after JSON diff expander. The component is presentational and
 * read-only: it never offers an edit/delete affordance, mirroring the
 * append-only `AdminAuditEntry` ledger. All styling comes from Notun Din token
 * classes (no hardcoded hex/px).
 */

const COLUMNS = ["When", "Actor", "Action", "Entity", "IP", ""] as const;

export interface AuditTableProps {
  entries: AuditEntry[];
  filters: AuditFilters;
  onFilterChange: (filters: AuditFilters) => void;
  onNext?: () => void;
  onPrevious?: () => void;
  hasNext: boolean;
  hasPrevious: boolean;
}

function formatWhen(iso: string): string {
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

export function AuditTable({
  entries,
  filters,
  onFilterChange,
  onNext,
  onPrevious,
  hasNext,
  hasPrevious,
}: AuditTableProps) {
  const setFilter = (key: keyof AuditFilters, value: string) => {
    const next: AuditFilters = { ...filters, [key]: value || undefined };
    delete next.cursor;
    onFilterChange(next);
  };

  return (
    <div className="space-y-s4">
      <AuditFilterBar filters={filters} onChange={setFilter} />

      {entries.length === 0 ? (
        <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
          <CardTitle>No audit entries</CardTitle>
          <CardDescription>
            No admin actions match these filters yet.
          </CardDescription>
        </Card>
      ) : (
        <Table aria-label="Audit log">
          <TableHead>
            <TableRow>
              {COLUMNS.map((c, i) => (
                <TableHeaderCell key={c || `col-${i}`}>{c}</TableHeaderCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {entries.map((entry) => (
              <AuditRow key={String(entry.id)} entry={entry} />
            ))}
          </TableBody>
        </Table>
      )}

      <div className="flex items-center justify-end gap-s3">
        <button
          type="button"
          onClick={onPrevious}
          disabled={!hasPrevious}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Previous
        </button>
        <button
          type="button"
          onClick={onNext}
          disabled={!hasNext}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Next
        </button>
      </div>
    </div>
  );
}

function AuditFilterBar({
  filters,
  onChange,
}: {
  filters: AuditFilters;
  onChange: (key: keyof AuditFilters, value: string) => void;
}) {
  const inputClass =
    "rounded-sm border border-line bg-card px-s3 py-s2 text-sm text-ink placeholder:text-muted";
  return (
    <div className="flex flex-wrap items-end gap-s3">
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Admin user
        <input
          type="text"
          aria-label="Filter by admin user"
          placeholder="id or system"
          value={filters.admin_user ?? ""}
          onChange={(e) => onChange("admin_user", e.target.value)}
          className={inputClass}
        />
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Action
        <input
          type="text"
          aria-label="Filter by action"
          placeholder="e.g. admin_user.disable"
          value={filters.action ?? ""}
          onChange={(e) => onChange("action", e.target.value)}
          className={inputClass}
        />
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Entity type
        <input
          type="text"
          aria-label="Filter by entity type"
          placeholder="app.model"
          value={filters.entity_type ?? ""}
          onChange={(e) => onChange("entity_type", e.target.value)}
          className={inputClass}
        />
      </label>
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

function AuditRow({ entry }: { entry: AuditEntry }) {
  const [open, setOpen] = useState(false);
  const hasDiff = entry.before_json !== null || entry.after_json !== null;
  const entity =
    entry.entity_type && entry.entity_id
      ? `${entry.entity_type} #${entry.entity_id}`
      : entry.entity_type || "—";

  return (
    <>
      <TableRow>
        <TableCell className="whitespace-nowrap">
          {formatWhen(entry.created_at)}
        </TableCell>
        <TableCell>{entry.actor}</TableCell>
        <TableCell className="font-mono text-xs">{entry.action}</TableCell>
        <TableCell>{entity}</TableCell>
        <TableCell className="font-mono text-xs">{entry.ip ?? "—"}</TableCell>
        <TableCell className="text-right">
          {hasDiff ? (
            <button
              type="button"
              aria-expanded={open}
              aria-label={open ? "Hide diff" : "Show diff"}
              onClick={() => setOpen((v) => !v)}
              className="rounded-button border border-line px-s3 py-s1 font-title text-xs font-semibold text-ink"
            >
              {open ? "Hide diff" : "Diff"}
            </button>
          ) : null}
        </TableCell>
      </TableRow>
      {open && hasDiff ? (
        <TableRow>
          <TableCell colSpan={COLUMNS.length} className="bg-sageBg">
            {entry.reason ? (
              <p className="mb-s2 text-sm text-mutedDk">
                <span className="font-semibold">Reason:</span> {entry.reason}
              </p>
            ) : null}
            <div className="grid grid-cols-1 gap-s3 md:grid-cols-2">
              <DiffPane title="Before" value={entry.before_json} />
              <DiffPane title="After" value={entry.after_json} />
            </div>
          </TableCell>
        </TableRow>
      ) : null}
    </>
  );
}

function DiffPane({
  title,
  value,
}: {
  title: string;
  value: Record<string, unknown> | null;
}) {
  return (
    <div>
      <p className="mb-s1 font-title text-xs font-semibold uppercase tracking-wide text-mutedDk">
        {title}
      </p>
      <pre className="overflow-x-auto rounded-sm border border-line bg-card p-s3 font-mono text-xs text-ink">
        {value === null ? "null" : JSON.stringify(value, null, 2)}
      </pre>
    </div>
  );
}
