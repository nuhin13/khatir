import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import type { ActivityEntry } from "@/lib/api/dashboard";

/**
 * Recent-activity feed — EPIC-11.T-009.
 *
 * Mirrors the `KhatirAdmin.jsx` dashboard "Recent activity" panel: a header
 * row, then a list of audit entries (status dot · action · actor · summary ·
 * relative time). Renders an empty state when no entries are available (the
 * audit list API lands in EPIC-11.T-011). Tokens only — no hardcoded values.
 */

function formatTime(iso: string): string {
  const ts = Date.parse(iso);
  if (Number.isNaN(ts)) return iso;
  return new Date(ts).toLocaleString();
}

export function ActivityFeed({ entries }: { entries: ActivityEntry[] }) {
  return (
    <Card className="p-0">
      <div className="border-b border-line px-s5 py-s4">
        <CardTitle>Recent activity</CardTitle>
        <CardDescription>Platform audit events</CardDescription>
      </div>

      {entries.length === 0 ? (
        <div className="px-s5 py-s8 text-center text-sm text-muted">
          No recent activity yet.
        </div>
      ) : (
        <ul>
          {entries.map((e, i) => (
            <li
              key={e.id}
              className={
                "flex items-center gap-s4 px-s5 py-s3" +
                (i < entries.length - 1 ? " border-b border-line" : "")
              }
            >
              <span
                aria-hidden
                className="size-s2 flex-shrink-0 rounded-pill bg-sage"
              />
              <div className="min-w-0 flex-1 text-sm text-ink">
                <span className="font-semibold">{e.action}</span>
                {e.actor ? (
                  <>
                    <span className="text-muted"> · </span>
                    <span className="font-semibold">{e.actor}</span>
                  </>
                ) : null}
                {e.summary ? (
                  <span className="text-ink2"> {e.summary}</span>
                ) : null}
              </div>
              <time
                dateTime={e.created_at}
                className="flex-shrink-0 font-mono text-xs text-muted"
              >
                {formatTime(e.created_at)}
              </time>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
