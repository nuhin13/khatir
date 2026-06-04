import { Card } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
import type { ChipProps } from "@/components/ui/chip";

/**
 * Platform KPI tile — EPIC-11.T-009.
 *
 * Mirrors the `KhatirAdmin.jsx` dashboard KPI tiles: uppercase label, large
 * title-font value, optional context chip. All colours/spacing/radii come from
 * the Notun Din token classes (no hardcoded hex/px).
 */
export interface KpiCardProps {
  label: string;
  value: string;
  hint?: string;
  hintTone?: ChipProps["tone"];
}

export function KpiCard({ label, value, hint, hintTone = "sage" }: KpiCardProps) {
  return (
    <Card>
      <div className="text-xs font-semibold uppercase tracking-wide text-muted">
        {label}
      </div>
      <div className="mt-s2 font-title text-3xl font-extrabold leading-none tracking-tight text-ink">
        {value}
      </div>
      {hint ? (
        <div className="mt-s3">
          <Chip tone={hintTone}>{hint}</Chip>
        </div>
      ) : null}
    </Card>
  );
}
