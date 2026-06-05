"use client";

import { Chip } from "@/components/ui/chip";
import {
  CHANNELS,
  CHANNEL_COST_BDT,
  type ChannelValue,
} from "@/lib/api/notifications";

/**
 * ChannelSelector — EPIC-15.T-011.
 *
 * Reusable checkbox-per-channel picker for the notification delivery channels
 * (in-app / WhatsApp / SMS / email). Each row shows the per-message cost chip
 * (free for `inapp`/`email`, ৳ for the paid SMS/WhatsApp channels) from the
 * shared `CHANNEL_COST_BDT` table. Controlled: the caller owns the selected
 * array and toggles via `onToggle`.
 *
 * Consumed by the notification composer (T-010) and available to any other
 * admin flow that needs to pick delivery channels. All colours/spacing/radii
 * come from Notun Din token classes — no hardcoded prototype hex/px.
 */

export const CHANNEL_LABELS: Record<ChannelValue, string> = {
  inapp: "In-app",
  whatsapp: "WhatsApp",
  sms: "SMS",
  email: "Email",
};

export interface ChannelSelectorProps {
  /** Currently selected channels. */
  value: ChannelValue[];
  /** Toggle a single channel on/off. */
  onToggle: (channel: ChannelValue) => void;
  /** Optional accessible label for the checkbox group. */
  ariaLabel?: string;
}

export function ChannelSelector({
  value,
  onToggle,
  ariaLabel = "Delivery channels",
}: ChannelSelectorProps) {
  return (
    <div
      role="group"
      aria-label={ariaLabel}
      className="grid gap-s2 sm:grid-cols-2"
    >
      {CHANNELS.map((channel) => {
        const selected = value.includes(channel);
        const cost = CHANNEL_COST_BDT[channel];
        return (
          <label
            key={channel}
            className={
              "flex cursor-pointer items-center justify-between rounded-card border px-s4 py-s3 transition-colors " +
              (selected
                ? "border-sage bg-sageBg"
                : "border-line bg-card hover:bg-sageBg")
            }
          >
            <span className="flex items-center gap-s2">
              <input
                type="checkbox"
                checked={selected}
                onChange={() => onToggle(channel)}
                className="h-4 w-4 accent-sage"
              />
              <span className="font-title text-sm font-semibold text-ink">
                {CHANNEL_LABELS[channel]}
              </span>
            </span>
            <Chip tone={cost === 0 ? "sage" : "butter"}>
              {cost === 0 ? "Free" : `৳${cost}/msg`}
            </Chip>
          </label>
        );
      })}
    </div>
  );
}
