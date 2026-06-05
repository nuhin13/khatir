"use client";

import { useState } from "react";
import { Power, AlertOctagon, ShieldCheck, Check, X } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Chip } from "@/components/ui/chip";
import {
  fetchKillSwitches,
  killSwitchesQueryKey,
  type KillSwitch,
} from "@/lib/api/killswitch";
import { KillSwitchDialog } from "./killswitch_dialog";

/**
 * Emergency kill-switch panel — EPIC-13.T-006.
 *
 * The "separate, prominent, visually distinct (red header)" emergency-disable
 * panel from `04_Admin_Portal_Khatir.md` §4.4.2 + `ui/KhatirAdmin.jsx` →
 * `KillSwitch`. Lists the 5 named kill-switches (T-003) — each shows its key,
 * description, current state, and last-changed actor/date. Each row has a
 * Disable/Enable action that opens the friction-heavy {@link KillSwitchDialog}
 * (MFA + reason + lawyer ref). A live switch is "ENABLED"; killing it flips
 * `enabled` to `false`.
 *
 * Safety-critical UI (task §15): a **red warning banner** appears whenever ANY
 * switch is OFF, so an operator can never miss that a feature is currently
 * killed. Super-only route guarding lives in the server page that renders this.
 * All colours/spacing/radii come from Notun Din token classes (no hardcoded
 * hex/px).
 */

/** The master "all public features" switch — visually escalated. */
const MASTER_KEY = "master_kill_switch";

function formatChanged(switch_: KillSwitch): string {
  // The backend exposes the audit `updated_at`/`updated_by` on each switch
  // (FeatureFlagSerializer, T-002). The immutable KillSwitchEvent log records
  // the full who/why/when; here we surface the most recent change.
  let when: string;
  try {
    when = new Date(switch_.updated_at).toLocaleString();
  } catch {
    when = switch_.updated_at;
  }
  const who =
    switch_.updated_by === null
      ? "system"
      : "admin #" + String(switch_.updated_by);
  return "Last changed " + when + " by " + who;
}

export function KillSwitchPanel() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: killSwitchesQueryKey,
    queryFn: fetchKillSwitches,
  });

  const anyOff = (data ?? []).some((s) => !s.enabled);

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Kill-switch</h1>
        <p className="mt-s1 text-sm text-muted">
          Emergency disable of reputation, warning, and public-facing features.
          Every action requires MFA re-confirmation, a written reason, and is
          permanently audit-logged.
        </p>
      </div>

      {/* Prominent red panel header — spec §4.4.2 "visually distinct". */}
      <Card className="flex items-start gap-s3 border-2 border-danger/40 bg-dangerBg">
        <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-pill bg-danger">
          <Power size={20} className="text-card" aria-hidden />
        </div>
        <div>
          <CardTitle className="text-danger">
            Emergency Kill-Switch Panel
          </CardTitle>
          <CardDescription className="text-ink2">
            Use these switches to immediately disable any reputation, warning,
            or public feature in response to legal or operational events.
            Changes propagate to all clients within ~60 seconds.
          </CardDescription>
        </div>
      </Card>

      {anyOff ? (
        <div
          role="alert"
          className="flex items-start gap-s3 rounded-card border-2 border-danger bg-dangerBg px-s5 py-s4"
        >
          <AlertOctagon
            size={20}
            className="mt-px flex-shrink-0 text-danger"
            aria-hidden
          />
          <div>
            <p className="font-title text-sm font-extrabold text-danger">
              One or more features are currently DISABLED
            </p>
            <p className="mt-s1 text-sm text-ink2">
              A kill-switch is OFF — the affected feature is unavailable across
              all client apps. Re-enable it only after the triggering issue is
              resolved.
            </p>
          </div>
        </div>
      ) : null}

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading kill-switches"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load kill-switches</CardTitle>
          <CardDescription>
            The kill-switch request failed. Check your connection and try again.
          </CardDescription>
          <Button variant="primary" onClick={() => void refetch()}>
            Retry
          </Button>
        </Card>
      ) : (
        <SwitchList switches={data} />
      )}
    </div>
  );
}

interface SwitchListProps {
  switches: KillSwitch[];
}

function SwitchList({ switches }: SwitchListProps) {
  const [confirming, setConfirming] = useState<KillSwitch | null>(null);

  return (
    <div className="grid gap-s3">
      {switches.map((s) => {
        const isMaster = s.key === MASTER_KEY;
        return (
          <Card
            key={s.key}
            className={
              isMaster
                ? "border-2 border-danger/40 bg-roseBg"
                : undefined
            }
          >
            <div className="flex items-start gap-s4">
              <div
                className={
                  "flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-pill " +
                  (s.enabled ? "bg-sageBg" : "bg-dangerBg")
                }
                aria-hidden
              >
                {s.enabled ? (
                  <Check size={20} className="text-sageDk" strokeWidth={2.5} />
                ) : (
                  <X size={20} className="text-danger" strokeWidth={2.5} />
                )}
              </div>

              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-s2">
                  <code className="font-mono text-sm font-bold text-ink">
                    {s.key}
                  </code>
                  {isMaster ? (
                    <Chip tone="danger">★ MASTER</Chip>
                  ) : null}
                  {s.enabled ? (
                    <Chip tone="sage">● ENABLED</Chip>
                  ) : (
                    <Chip tone="danger">○ DISABLED</Chip>
                  )}
                </div>
                {s.description ? (
                  <p className="mt-s2 text-sm leading-relaxed text-ink2">
                    {s.description}
                  </p>
                ) : null}
                <p className="mt-s2 flex items-center gap-s1 font-mono text-xs text-muted">
                  <ShieldCheck size={12} className="text-muted" aria-hidden />
                  {formatChanged(s)}
                </p>
              </div>

              <Button
                variant={s.enabled ? "danger" : "secondary"}
                onClick={() => setConfirming(s)}
                className="flex-shrink-0"
              >
                {s.enabled ? "Disable" : "Enable"}
              </Button>
            </div>
          </Card>
        );
      })}

      {confirming !== null ? (
        <KillSwitchDialog
          switch_={confirming}
          onClose={() => setConfirming(null)}
        />
      ) : null}
    </div>
  );
}
