"use client";

import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from "@/components/ui/table";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import {
  CONSENT_TYPES,
  CONSENT_TYPE_LABELS,
  type ConsentRecord,
  type ConsentFilters,
  type ConsentType,
} from "@/lib/api/consent";

/**
 * Consent-records table — EPIC-16.T-007.
 *
 * Renders the filter bar (user + consent type) and the paginated, read-only
 * table of logged consent events: user, consent type, granted, revoked,
 * expires. The component is presentational and read-only — `ConsentRecord` is
 * append-only, so it never offers an edit/delete affordance. All styling comes
 * from Notun Din token classes (no hardcoded hex/px).
 */

const COLUMNS = [
  "User",
  "Consent type",
  "Granted",
  "Revoked",
  "Expires",
] as const;

export interface ConsentTableProps {
  records: ConsentRecord[];
  filters: ConsentFilters;
  onFilterChange: (filters: ConsentFilters) => void;
  onNext?: () => void;
  onPrevious?: () => void;
  hasNext: boolean;
  hasPrevious: boolean;
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

function consentTypeLabel(value: string): string {
  return CONSENT_TYPE_LABELS[value as ConsentType] ?? value;
}

export function ConsentTable({
  records,
  filters,
  onFilterChange,
  onNext,
  onPrevious,
  hasNext,
  hasPrevious,
}: ConsentTableProps) {
  const setFilter = (key: keyof ConsentFilters, value: string) => {
    const next: ConsentFilters = { ...filters, [key]: value || undefined };
    delete next.page;
    onFilterChange(next);
  };

  return (
    <div className="space-y-s4">
      <ConsentFilterBar filters={filters} onChange={setFilter} />

      {records.length === 0 ? (
        <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
          <CardTitle>No consent records</CardTitle>
          <CardDescription>
            No consent events match these filters yet.
          </CardDescription>
        </Card>
      ) : (
        <Table aria-label="Consent records">
          <TableHead>
            <TableRow>
              {COLUMNS.map((c) => (
                <TableHeaderCell key={c}>{c}</TableHeaderCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {records.map((record) => (
              <TableRow key={String(record.id)}>
                <TableCell className="font-mono text-xs">
                  {record.user === null ? "—" : `#${record.user}`}
                </TableCell>
                <TableCell>{consentTypeLabel(record.consent_type)}</TableCell>
                <TableCell className="whitespace-nowrap">
                  {formatWhen(record.granted_at)}
                </TableCell>
                <TableCell className="whitespace-nowrap">
                  {formatWhen(record.revoked_at)}
                </TableCell>
                <TableCell className="whitespace-nowrap">
                  {formatWhen(record.expires_at)}
                </TableCell>
              </TableRow>
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

function ConsentFilterBar({
  filters,
  onChange,
}: {
  filters: ConsentFilters;
  onChange: (key: keyof ConsentFilters, value: string) => void;
}) {
  const inputClass =
    "rounded-sm border border-line bg-card px-s3 py-s2 text-sm text-ink placeholder:text-muted";
  return (
    <div className="flex flex-wrap items-end gap-s3">
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        User
        <input
          type="text"
          aria-label="Filter by user"
          placeholder="user id"
          value={filters.user ?? ""}
          onChange={(e) => onChange("user", e.target.value)}
          className={inputClass}
        />
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Consent type
        <select
          aria-label="Filter by consent type"
          value={filters.consent_type ?? ""}
          onChange={(e) => onChange("consent_type", e.target.value)}
          className={inputClass}
        >
          <option value="">All types</option>
          {CONSENT_TYPES.map((type) => (
            <option key={type} value={type}>
              {CONSENT_TYPE_LABELS[type]}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Granted from
        <input
          type="date"
          aria-label="Filter granted from date"
          value={filters.granted_from ?? ""}
          onChange={(e) => onChange("granted_from", e.target.value)}
          className={inputClass}
        />
      </label>
      <label className="flex flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Granted to
        <input
          type="date"
          aria-label="Filter granted to date"
          value={filters.granted_to ?? ""}
          onChange={(e) => onChange("granted_to", e.target.value)}
          className={inputClass}
        />
      </label>
    </div>
  );
}
