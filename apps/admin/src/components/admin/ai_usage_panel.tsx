"use client";

import { useMemo, useState } from "react";
import { AlertTriangle, CheckCircle2 } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from "@/components/ui/table";
import { AI_CATEGORIES, type AICategory } from "@/lib/api/ai-providers";
import {
  aiUsageQueryKey,
  errorRate,
  fetchAIUsage,
  successRate,
  type AIUsage,
  type AIUsageRange,
  type AIUsageRow,
} from "@/lib/api/ai-usage";

/**
 * AI-usage panel — EPIC-14.T-012 (`04_Admin_Portal_Khatir.md` §4.6.3).
 *
 * Per-category volume dashboard: requests, tokens, USD cost, and success/error
 * rate, with a running cost total for the billing period (task §15) and a date
 * filter. The super/ops route guard lives in the server page that renders this.
 *
 * The committed usage endpoint (T-009) aggregates volume only — it has no
 * latency column and no standalone failover-event stream — so the "failover &
 * errors" log surfaces every category that logged at least one failed call,
 * derived from `call_count − success_count`. All colours/spacing/radii come
 * from Notun Din token classes; no hardcoded prototype hex/px.
 */

/** Tab/row labels per the spec §4.6.1 table — shared vocabulary with the editor. */
const CATEGORY_LABELS: Record<AICategory, string> = {
  chat: "Chat / LLM",
  voice: "Voice / ASR",
  ocr: "OCR / Vision",
  lease: "Lease generation",
};

const intFmt = new Intl.NumberFormat("en-US");

/** USD cost string → "$1,234.56"; tolerates a malformed value gracefully. */
function formatUsd(value: string): string {
  const n = Number(value);
  if (!Number.isFinite(n)) return "$" + value;
  return (
    "$" +
    n.toLocaleString("en-US", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
  );
}

/** Fraction in [0,1] → "97.3%", or an em-dash when there is no data. */
function formatRate(rate: number | null): string {
  if (rate === null) return "—";
  return (rate * 100).toFixed(1) + "%";
}

export function AIUsagePanel() {
  const [range, setRange] = useState<AIUsageRange>({});

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: aiUsageQueryKey(range),
    queryFn: () => fetchAIUsage(range),
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">AI usage</h1>
        <p className="mt-s1 text-sm text-muted">
          Call volume, token consumption, and cost per AI category. Costs are in
          USD, read from the AI usage log; the total is the running cost for the
          selected period.
        </p>
      </div>

      <DateFilter range={range} onChange={setRange} />

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading AI usage"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load AI usage</CardTitle>
          <CardDescription>
            The AI-usage request failed. Check your connection and try again.
          </CardDescription>
          <Button onClick={() => void refetch()}>Retry</Button>
        </Card>
      ) : (
        <UsageContent usage={data} />
      )}
    </div>
  );
}

interface DateFilterProps {
  range: AIUsageRange;
  onChange: (range: AIUsageRange) => void;
}

const DATE_INPUT_CLASS =
  "mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink focus:border-sage focus:outline-none";

function DateFilter({ range, onChange }: DateFilterProps) {
  return (
    <form
      aria-label="Usage date filter"
      className="flex flex-wrap items-end gap-s4 rounded-card border border-line bg-card px-s5 py-s4 shadow-sm"
      onSubmit={(e) => e.preventDefault()}
    >
      <label className="block">
        <span className="font-title text-xs font-semibold text-mutedDk">
          From
        </span>
        <input
          type="date"
          value={range.from ?? ""}
          max={range.to || undefined}
          onChange={(e) =>
            onChange({ ...range, from: e.target.value || undefined })
          }
          className={DATE_INPUT_CLASS}
        />
      </label>
      <label className="block">
        <span className="font-title text-xs font-semibold text-mutedDk">
          To
        </span>
        <input
          type="date"
          value={range.to ?? ""}
          min={range.from || undefined}
          onChange={(e) =>
            onChange({ ...range, to: e.target.value || undefined })
          }
          className={DATE_INPUT_CLASS}
        />
      </label>
      <Button
        type="button"
        variant="ghost"
        onClick={() => onChange({})}
        disabled={!range.from && !range.to}
      >
        Clear
      </Button>
    </form>
  );
}

interface UsageContentProps {
  usage: AIUsage;
}

function UsageContent({ usage }: UsageContentProps) {
  const failovers = useMemo(
    () =>
      usage.by_category.filter((r) => r.call_count - r.success_count > 0),
    [usage.by_category],
  );

  return (
    <div className="space-y-s5">
      <TotalsBar usage={usage} />
      <UsageTable rows={usage.by_category} />
      <FailoverLog rows={failovers} />
    </div>
  );
}

function TotalsBar({ usage }: UsageContentProps) {
  const { totals } = usage;
  return (
    <div className="grid gap-s4 sm:grid-cols-2 lg:grid-cols-4">
      <SummaryCard label="Requests" value={intFmt.format(totals.request_count)} />
      <SummaryCard label="Tokens used" value={intFmt.format(totals.tokens_used)} />
      <SummaryCard
        label="Total cost (USD)"
        value={formatUsd(totals.cost_usd)}
        emphasis
      />
      <SummaryCard
        label="Success rate"
        value={formatRate(successRate(totals))}
      />
    </div>
  );
}

interface SummaryCardProps {
  label: string;
  value: string;
  emphasis?: boolean;
}

function SummaryCard({ label, value, emphasis }: SummaryCardProps) {
  return (
    <Card>
      <CardTitle className="text-xs uppercase tracking-wide text-muted">
        {label}
      </CardTitle>
      <p
        className={
          "mt-s1 font-title font-bold " +
          (emphasis ? "text-xl text-sageDk" : "text-xl text-ink")
        }
      >
        {value}
      </p>
    </Card>
  );
}

interface UsageTableProps {
  rows: AIUsageRow[];
}

function UsageTable({ rows }: UsageTableProps) {
  // Stable category order, even for categories with no logged usage.
  const byCategory = new Map(rows.map((r) => [r.category, r]));

  return (
    <div className="space-y-s2">
      <h2 className="font-title text-base font-bold text-ink">
        Usage by category
      </h2>
      <Table aria-label="AI usage by category">
        <TableHead>
          <TableRow>
            <TableHeaderCell scope="col">Category</TableHeaderCell>
            <TableHeaderCell scope="col" className="text-right">
              Requests
            </TableHeaderCell>
            <TableHeaderCell scope="col" className="text-right">
              Tokens
            </TableHeaderCell>
            <TableHeaderCell scope="col" className="text-right">
              Cost (USD)
            </TableHeaderCell>
            <TableHeaderCell scope="col" className="text-right">
              Error rate
            </TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {AI_CATEGORIES.map((cat) => {
            const row = byCategory.get(cat);
            const er = row ? errorRate(row) : null;
            const erElevated = er !== null && er > 0;
            return (
              <TableRow key={cat}>
                <TableCell className="font-title font-semibold">
                  {CATEGORY_LABELS[cat]}
                </TableCell>
                <TableCell className="text-right font-mono text-xs">
                  {intFmt.format(row?.request_count ?? 0)}
                </TableCell>
                <TableCell className="text-right font-mono text-xs">
                  {intFmt.format(row?.tokens_used ?? 0)}
                </TableCell>
                <TableCell className="text-right font-mono text-xs">
                  {formatUsd(row?.cost_usd ?? "0")}
                </TableCell>
                <TableCell className="text-right">
                  <span
                    className={
                      "font-mono text-xs " +
                      (erElevated ? "font-semibold text-roseDk" : "text-muted")
                    }
                  >
                    {formatRate(er)}
                  </span>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}

interface FailoverLogProps {
  rows: AIUsageRow[];
}

/**
 * Failover & error log. The endpoint exposes no standalone failover stream
 * (T-009), so this lists each category that logged at least one failed call —
 * the closest faithful signal available from the aggregated counts.
 */
function FailoverLog({ rows }: FailoverLogProps) {
  return (
    <div className="overflow-hidden rounded-card border border-line bg-card shadow-sm">
      <div className="border-b border-line px-s5 py-s4">
        <h2 className="font-title text-base font-bold text-ink">
          Failover &amp; errors
        </h2>
        <p className="mt-s1 text-xs text-muted">
          Categories with at least one failed call in the selected period.
        </p>
      </div>
      {rows.length === 0 ? (
        <div className="flex flex-col items-center gap-s2 px-s5 py-s8 text-center">
          <CheckCircle2 size={24} className="text-sageDk" aria-hidden />
          <p className="text-sm text-muted">
            No failed calls recorded for this period.
          </p>
        </div>
      ) : (
        <ul className="divide-y divide-line">
          {rows.map((row) => {
            const failures = row.call_count - row.success_count;
            return (
              <li
                key={row.category}
                className="flex items-center justify-between gap-s4 px-s5 py-s4"
              >
                <div className="flex items-center gap-s3">
                  <AlertTriangle
                    size={18}
                    className="flex-shrink-0 text-roseDk"
                    aria-hidden
                  />
                  <div>
                    <p className="font-title text-sm font-semibold text-ink">
                      {CATEGORY_LABELS[row.category]}
                    </p>
                    <p className="mt-s1 text-xs text-muted">
                      {intFmt.format(failures)} of{" "}
                      {intFmt.format(row.call_count)} calls failed
                    </p>
                  </div>
                </div>
                <Chip tone="rose">{formatRate(errorRate(row))} errors</Chip>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
