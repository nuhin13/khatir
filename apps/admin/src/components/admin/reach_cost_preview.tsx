"use client";

import { Users } from "lucide-react";
import { Card, CardTitle } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
import { CHANNEL_LABELS } from "@/components/admin/channel_selector";
import { estimateCost, type ChannelValue } from "@/lib/api/notifications";

/**
 * ReachCostPreview — EPIC-15.T-014.
 *
 * Reusable widget that surfaces the audience reach count and estimated cost
 * before composing a notification (design source `04_Admin_Portal_Khatir.md`
 * §4.5.1 → "Reach summary (recipient count from audience filter)" + "Cost
 * estimate (channels × recipients × per-channel cost)"). Consumed by the
 * notification composer (T-010) as its preview sidebar.
 *
 * Reach resolution: the backend only resolves the authoritative reach when a
 * broadcast is composed (`POST /admin/api/notifications`, T-007 — there is no
 * standalone estimate endpoint). For broad audiences (`all` / `role` /
 * `segment`) the exact reach is therefore unknown until send, so the widget
 * shows a dash and explains that the server resolves it. For a `specific`
 * audience the reach is the explicit recipient count, known client-side. The
 * cost mirrors the backend formula via the shared {@link estimateCost} helper
 * (`reach × Σ per-channel cost`).
 *
 * Controlled + presentational: the caller owns reach/channels/state and may
 * pass an action node (e.g. the send button) rendered at the foot. All
 * colours/spacing/radii come from Notun Din token classes — no hardcoded
 * prototype hex/px.
 */

const taka = (amount: number): string =>
  "৳" +
  amount.toLocaleString("en-US", {
    minimumFractionDigits: amount % 1 === 0 ? 0 : 2,
    maximumFractionDigits: 2,
  });

export interface ReachCostPreviewProps {
  /** Selected delivery channels (drives the cost and the channel chips). */
  channels: ChannelValue[];
  /**
   * Resolved recipient count, or `null` when the reach is not yet known
   * (broad audiences are resolved server-side at send time).
   */
  reach: number | null;
  /** Optional action rendered at the foot of the card (e.g. a send button). */
  action?: React.ReactNode;
  /** Optional error message shown above the action. */
  errorMessage?: string | null;
}

export function ReachCostPreview({
  channels,
  reach,
  action,
  errorMessage,
}: ReachCostPreviewProps) {
  const cost = reach === null ? null : estimateCost(reach, channels);

  return (
    <Card className="h-fit space-y-s4 lg:sticky lg:top-s5">
      <CardTitle className="flex items-center gap-s2">
        <Users size={18} className="text-sage" aria-hidden /> Reach &amp; cost
      </CardTitle>

      <dl className="space-y-s3">
        <div className="flex items-center justify-between">
          <dt className="text-sm text-muted">Estimated reach</dt>
          <dd className="font-title text-lg font-bold text-ink">
            {reach === null ? "—" : reach.toLocaleString("en-US")}
          </dd>
        </div>
        <div className="flex items-center justify-between">
          <dt className="text-sm text-muted">Estimated cost</dt>
          <dd className="font-title text-lg font-bold text-ink">
            {cost === null ? "—" : taka(cost)}
          </dd>
        </div>
      </dl>

      <div className="flex flex-wrap gap-s2">
        {channels.length === 0 ? (
          <span className="text-xs text-muted">No channels selected</span>
        ) : (
          channels.map((c) => (
            <Chip key={c} tone="neutral">
              {CHANNEL_LABELS[c]}
            </Chip>
          ))
        )}
      </div>

      {reach === null ? (
        <p className="text-xs text-muted">
          Final reach and cost are resolved on the server when you send.
        </p>
      ) : null}

      {errorMessage ? (
        <p role="alert" className="text-sm text-roseDk">
          {errorMessage}
        </p>
      ) : null}

      {action}
    </Card>
  );
}
