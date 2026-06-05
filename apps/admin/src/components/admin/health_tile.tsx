import { Card, CardTitle } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
import type { ChipProps } from "@/components/ui/chip";
import type { Health, HealthStatus } from "@/lib/api/dashboard";

/**
 * System-health panel — EPIC-11.T-009.
 *
 * Mirrors the `KhatirAdmin.jsx` dashboard "System health" card: one row per
 * dependency (app / database / cache) with a status chip. Reflects the live
 * `health` block from `GET /admin/api/dashboard`. Tokens only.
 */

const TONE_BY_STATUS: Record<HealthStatus, ChipProps["tone"]> = {
  ok: "sage",
  degraded: "butter",
  down: "danger",
};

function StatusRow({
  label,
  status,
  last,
}: {
  label: string;
  status: HealthStatus;
  last?: boolean;
}) {
  return (
    <div
      className={
        "flex items-center justify-between py-s2" +
        (last ? "" : " border-b border-line")
      }
    >
      <span className="text-sm text-ink2">{label}</span>
      <Chip tone={TONE_BY_STATUS[status]}>{status.toUpperCase()}</Chip>
    </div>
  );
}

export function HealthTile({ health }: { health: Health }) {
  return (
    <Card>
      <CardTitle className="mb-s3">System health</CardTitle>
      <StatusRow label="App" status={health.app === "ok" ? "ok" : "down"} />
      <StatusRow label="Database" status={health.database} />
      <StatusRow label="Cache" status={health.cache} last />
    </Card>
  );
}
