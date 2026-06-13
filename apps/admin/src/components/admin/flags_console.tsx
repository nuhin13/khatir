"use client";

import { useState } from "react";
import { Flag } from "lucide-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import { Toggle } from "@/components/ui/toggle";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeaderCell,
  TableRow,
} from "@/components/ui/table";
import {
  fetchFeatureFlags,
  toggleFeatureFlag,
  featureFlagsQueryKey,
  type FeatureFlag,
  type FlagScope,
} from "@/lib/api/flags";

/**
 * Feature-flags console — EPIC-13.T-005.
 *
 * The feature-management panel from `04_Admin_Portal_Khatir.md` §Feature Flags
 * (`ui/KhatirAdmin.jsx` → `Features`): a table of every flag (key, description,
 * scope) with a toggle switch per row. Toggling first opens a confirm dialog —
 * a flag change propagates to all clients within ~60s, so the switch is never
 * flipped without an explicit confirmation. On confirm it calls the dedicated
 * `PATCH /admin/api/flags/{key}/toggle` endpoint (T-002, audited + cache-busted)
 * and refetches the list so the table reflects the new state.
 *
 * This is the everyday feature panel; the emergency kill-switch lives on a
 * separate page (T-006) with extra security friction (MFA + mandatory reason).
 * The super/ops route guard lives in the server page that renders this. All
 * colours/spacing/radii come from Notun Din token classes (no hardcoded hex/px).
 */

const SCOPE_LABELS: Record<FlagScope, string> = {
  global: "Global",
  role: "Role",
  user: "User",
};

export function FlagsConsole() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: featureFlagsQueryKey,
    queryFn: fetchFeatureFlags,
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Features</h1>
        <p className="mt-s1 text-sm text-muted">
          Feature flags control what is live in production. Toggling a flag takes
          effect across all clients within 60 seconds and is fully audit-logged.
        </p>
      </div>

      <Card className="flex items-start gap-s3 border-sage bg-sageBg">
        <Flag size={20} className="mt-s1 flex-shrink-0 text-sageDk" aria-hidden />
        <div>
          <CardTitle className="text-sageDk">
            Changes propagate within ~60 seconds
          </CardTitle>
          <CardDescription className="text-mutedDk">
            Each toggle requires a confirmation before it is applied. The
            emergency kill-switch panel is separate and needs MFA plus a written
            reason.
          </CardDescription>
        </div>
      </Card>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading feature flags"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load feature flags</CardTitle>
          <CardDescription>
            The feature-flag request failed. Check your connection and try again.
          </CardDescription>
          <button
            type="button"
            onClick={() => void refetch()}
            className="mt-s2 rounded-button bg-ink px-s5 py-s2 font-title text-sm font-semibold text-card"
          >
            Retry
          </button>
        </Card>
      ) : (
        <FlagTable flags={data} />
      )}
    </div>
  );
}

interface FlagTableProps {
  flags: FeatureFlag[];
}

function FlagTable({ flags }: FlagTableProps) {
  const [confirming, setConfirming] = useState<FeatureFlag | null>(null);

  return (
    <div className="overflow-hidden rounded-card border border-line bg-card shadow-sm">
      <div className="border-b border-line px-s5 py-s4">
        <h2 className="font-title text-base font-bold text-ink">
          Feature flags
        </h2>
        <p className="mt-s1 text-xs text-muted">
          {flags.length} flag{flags.length === 1 ? "" : "s"} · live-configurable
          · every change is audit-logged
        </p>
      </div>

      <Table className="rounded-none border-0">
        <TableHead>
          <TableRow>
            <TableHeaderCell>Flag</TableHeaderCell>
            <TableHeaderCell>Scope</TableHeaderCell>
            <TableHeaderCell className="text-right">Status</TableHeaderCell>
            <TableHeaderCell className="text-right">
              <span className="sr-only">Toggle</span>
            </TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {flags.map((flag) => (
            <TableRow key={flag.key}>
              <TableCell>
                <code className="font-mono text-xs text-ink">{flag.key}</code>
                {flag.description ? (
                  <div className="mt-s1 text-xs text-muted">
                    {flag.description}
                  </div>
                ) : null}
              </TableCell>
              <TableCell>
                <Chip tone="neutral">{SCOPE_LABELS[flag.scope]}</Chip>
              </TableCell>
              <TableCell className="text-right">
                {flag.enabled ? (
                  <Chip tone="sage">On</Chip>
                ) : (
                  <Chip tone="neutral">Off</Chip>
                )}
              </TableCell>
              <TableCell className="text-right">
                <div className="flex justify-end">
                  <Toggle
                    checked={flag.enabled}
                    onChange={() => setConfirming(flag)}
                    label={"Toggle " + flag.key}
                  />
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {confirming !== null ? (
        <ToggleConfirm
          flag={confirming}
          onClose={() => setConfirming(null)}
        />
      ) : null}
    </div>
  );
}

interface ToggleConfirmProps {
  flag: FeatureFlag;
  onClose: () => void;
}

/** Confirmation dialog shown before a flag's `enabled` state is flipped. */
function ToggleConfirm({ flag, onClose }: ToggleConfirmProps) {
  const queryClient = useQueryClient();
  const target = !flag.enabled;

  const toggle = useMutation({
    mutationFn: () => toggleFeatureFlag(flag.key),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: featureFlagsQueryKey });
      onClose();
    },
  });

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={"Toggle flag " + flag.key}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md overflow-hidden rounded-card bg-card shadow-lg"
      >
        <header className="border-b border-line px-s5 py-s4">
          <h2 className="font-title text-base font-extrabold text-ink">
            {target ? "Enable" : "Disable"} feature flag
          </h2>
          <p className="mt-s1 font-mono text-xs text-muted">{flag.key}</p>
        </header>

        <div className="px-s5 py-s5">
          <p className="text-sm leading-relaxed text-mutedDk">
            This will <b className="text-ink">{target ? "enable" : "disable"}</b>{" "}
            the <b className="text-ink">{flag.key}</b> flag across all clients
            within ~60 seconds. The change is permanently audit-logged.
          </p>
          {toggle.isError ? (
            <p role="alert" className="mt-s3 text-sm text-roseDk">
              Could not toggle the flag. Try again.
            </p>
          ) : null}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={target ? "primary" : "danger"}
            onClick={() => toggle.mutate()}
            disabled={toggle.isPending}
          >
            {toggle.isPending
              ? "Applying…"
              : target
                ? "Enable flag"
                : "Disable flag"}
          </Button>
        </footer>
      </div>
    </div>
  );
}
