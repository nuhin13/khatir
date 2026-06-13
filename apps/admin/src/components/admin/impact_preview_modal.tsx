"use client";

import { AlertTriangle, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";

/**
 * Tier-impact preview modal — EPIC-12.T-006.
 *
 * Reusable confirmation surface shown before a pricing-tier change is applied.
 * It mirrors the "Impact preview" panel in `KhatirAdmin.jsx` (Pricing › Edit
 * tier): subscribers affected, the monthly revenue delta (before/after), and a
 * warning when the change would strip NID verification from existing
 * subscribers.
 *
 * The component is presentational and reusable: it takes a {@link TierImpact}
 * payload as a prop rather than fetching itself, so the pricing editor (T-005)
 * and the manual-upgrade flow (T-008) can both reuse it after calling the
 * preview endpoint. All colours/spacing/radii come from Notun Din token classes
 * (no hardcoded hex/px).
 */

export interface TierImpact {
  /** Display label of the tier being changed (e.g. "Unlimited Annual"). */
  tierLabel: string;
  /** Stable tier key (e.g. "unlimited_annual"). */
  tierKey?: string;
  /** Current monthly price in BDT (0 means FREE). */
  oldMonthly: number;
  /** Proposed monthly price in BDT (0 means FREE). */
  newMonthly: number;
  /** Active subscribers on this tier today. */
  subscribersAffected: number;
  /** Whether the tier currently includes NID verification. */
  oldIncludesVerification: boolean;
  /** Whether the proposed tier includes NID verification. */
  newIncludesVerification: boolean;
}

export interface ImpactPreviewModalProps {
  /** Controls visibility. When false the modal renders nothing. */
  open: boolean;
  /** Impact payload. Omit (with `loading`) while the preview is in flight. */
  impact?: TierImpact;
  /** Show the loading skeleton instead of the data. */
  loading?: boolean;
  /** Invoked when the user dismisses the modal (backdrop, ✕, or Cancel). */
  onClose: () => void;
  /** Optional confirm handler. When provided, an "Apply change" CTA is shown. */
  onConfirm?: () => void;
  /** Disable the confirm CTA (e.g. while a reason is still required). */
  confirmDisabled?: boolean;
}

function formatBdt(value: number): string {
  return value === 0 ? "FREE" : `৳${value.toLocaleString()}`;
}

/** Estimated monthly revenue delta = (new − old) × subscribers. */
export function revenueDelta(impact: TierImpact): number {
  return (impact.newMonthly - impact.oldMonthly) * impact.subscribersAffected;
}

function formatDelta(delta: number): string {
  const sign = delta > 0 ? "+" : delta < 0 ? "−" : "";
  return `${sign}৳${Math.abs(delta).toLocaleString()}/mo`;
}

/** True when the change removes NID verification from existing subscribers. */
export function losesVerification(impact: TierImpact): boolean {
  return (
    impact.oldIncludesVerification &&
    !impact.newIncludesVerification &&
    impact.subscribersAffected > 0
  );
}

export function ImpactPreviewModal({
  open,
  impact,
  loading = false,
  onClose,
  onConfirm,
  confirmDisabled = false,
}: ImpactPreviewModalProps) {
  if (!open) return null;

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Tier impact preview"
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg overflow-hidden rounded-card bg-card shadow-lg"
      >
        <header className="flex items-center justify-between border-b border-line px-s5 py-s4">
          <div>
            <h2 className="font-title text-base font-extrabold text-ink">
              Impact preview
            </h2>
            {impact?.tierKey ? (
              <p className="mt-s1 font-mono text-xs text-muted">
                {impact.tierKey}
              </p>
            ) : null}
          </div>
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="rounded-button p-s1 text-muted hover:bg-sageBg"
          >
            <X size={16} />
          </button>
        </header>

        <div className="px-s5 py-s5">
          {loading || !impact ? (
            <ImpactSkeleton />
          ) : (
            <ImpactBody impact={impact} />
          )}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          {onConfirm ? (
            <Button
              variant="primary"
              onClick={onConfirm}
              disabled={loading || !impact || confirmDisabled}
            >
              Apply change
            </Button>
          ) : null}
        </footer>
      </div>
    </div>
  );
}

function ImpactBody({ impact }: { impact: TierImpact }) {
  const delta = revenueDelta(impact);
  const warn = losesVerification(impact);

  return (
    <div className="space-y-s4">
      <p className="text-sm leading-relaxed text-mutedDk">
        Changing <b className="text-ink">{impact.tierLabel}</b> from{" "}
        <code className="rounded-chip bg-sageBg px-s2 py-s1 font-mono text-xs text-sageDk">
          {formatBdt(impact.oldMonthly)}
        </code>{" "}
        to{" "}
        <code className="rounded-chip bg-sageBg px-s2 py-s1 font-mono text-xs text-sageDk">
          {formatBdt(impact.newMonthly)}
        </code>
        .
      </p>

      <dl className="grid grid-cols-2 gap-s4">
        <div>
          <dt className="text-xs font-semibold uppercase tracking-wide text-muted">
            Subscribers affected
          </dt>
          <dd className="mt-s1 font-title text-2xl font-extrabold leading-none text-ink">
            {impact.subscribersAffected.toLocaleString()}
          </dd>
        </div>
        <div>
          <dt className="text-xs font-semibold uppercase tracking-wide text-muted">
            Est. monthly revenue
          </dt>
          <dd
            className={cn(
              "mt-s1 font-mono text-2xl font-extrabold leading-none",
              delta > 0
                ? "text-sageDk"
                : delta < 0
                  ? "text-roseDk"
                  : "text-ink",
            )}
          >
            {formatDelta(delta)}
          </dd>
        </div>
      </dl>

      {warn ? (
        <div
          role="alert"
          className="flex items-start gap-s2 rounded-tile border border-butter bg-butterBg p-s4"
        >
          <AlertTriangle
            size={16}
            className="mt-s1 flex-shrink-0 text-roseDk"
            aria-hidden
          />
          <div>
            <p className="font-title text-xs font-bold uppercase tracking-wide text-roseDk">
              NID verification will be removed
            </p>
            <p className="mt-s1 text-sm text-mutedDk">
              {impact.subscribersAffected.toLocaleString()} existing subscriber
              {impact.subscribersAffected === 1 ? "" : "s"} will lose NID
              verification on this tier.
            </p>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function ImpactSkeleton() {
  return (
    <div className="space-y-s4" aria-busy="true" aria-label="Loading impact">
      <div className="h-s4 w-3/4 animate-pulse rounded-sm bg-line" />
      <div className="grid grid-cols-2 gap-s4">
        <div className="h-s8 animate-pulse rounded-sm bg-line" />
        <div className="h-s8 animate-pulse rounded-sm bg-line" />
      </div>
    </div>
  );
}
