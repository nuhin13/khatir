"use client";

import { useState } from "react";
import { AlertTriangle, Lock } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import {
  killSwitchesQueryKey,
  toggleKillSwitch,
  type KillSwitch,
} from "@/lib/api/killswitch";

/**
 * Kill-switch confirmation dialog — EPIC-13.T-006.
 *
 * The friction-heavy confirm step from `04_Admin_Portal_Khatir.md` §4.4.2 +
 * `ui/KhatirAdmin.jsx` → `KillSwitch`. Throwing a switch is legally critical,
 * so before the `enabled` state is flipped the operator must supply ALL of:
 *
 * 1. a written **reason** (mandatory, ≥ 20 chars — spec §4.4.2),
 * 2. an optional **lawyer reference**,
 * 3. a fresh **6-digit TOTP** re-confirmation (required even inside an active
 *    session — T-003 §15, intentional friction).
 *
 * On confirm it POSTs to `/admin/api/killswitches/{key}/toggle` (T-003): the
 * backend re-verifies the TOTP, records an immutable `KillSwitchEvent`, audits
 * the actor, and busts the public-config cache (≤60s propagation). A wrong MFA
 * code is rejected with 403 and surfaced inline. All colours/spacing/radii come
 * from Notun Din token classes (no hardcoded hex/px).
 */

/** Minimum reason length enforced by the spec (§4.4.2 — "min 20 chars"). */
export const MIN_REASON_LENGTH = 20;

interface KillSwitchDialogProps {
  /** The switch being toggled. */
  switch_: KillSwitch;
  onClose: () => void;
}

export function KillSwitchDialog({ switch_, onClose }: KillSwitchDialogProps) {
  const queryClient = useQueryClient();
  // A live (enabled) switch is being KILLED; a dead one is being restored.
  const killing = switch_.enabled;

  const [reason, setReason] = useState("");
  const [lawyerReference, setLawyerReference] = useState("");
  const [mfaCode, setMfaCode] = useState("");

  const toggle = useMutation({
    mutationFn: () =>
      toggleKillSwitch({
        key: switch_.key,
        mfaCode: mfaCode.trim(),
        reason: reason.trim(),
        lawyerReference: lawyerReference.trim(),
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: killSwitchesQueryKey });
      onClose();
    },
  });

  const reasonValid = reason.trim().length >= MIN_REASON_LENGTH;
  const mfaValid = /^\d{6}$/.test(mfaCode.trim());
  const canConfirm = reasonValid && mfaValid && !toggle.isPending;

  const verb = killing ? "Disable" : "Enable";

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-50 flex items-center justify-center bg-ink/50 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={verb + " kill-switch " + switch_.key}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg overflow-hidden rounded-card border-2 border-danger/40 bg-card shadow-lg"
      >
        <header className="flex items-center gap-s3 border-b border-line px-s5 py-s4">
          <AlertTriangle size={20} className="flex-shrink-0 text-danger" aria-hidden />
          <h2 className="font-title text-base font-extrabold text-danger">
            Confirm: {verb} {switch_.key}
          </h2>
        </header>

        <div className="grid gap-s4 px-s5 py-s5">
          <div className="rounded-md bg-dangerBg px-s4 py-s3 text-sm leading-relaxed text-ink2">
            This will{" "}
            <b className="text-danger">
              immediately {killing ? "disable" : "re-enable"}
            </b>{" "}
            the <b className="text-ink">{switch_.key}</b> feature across all
            clients on next refresh (within ~60 seconds).
            {killing ? " All affected users will lose access." : ""} This action
            is permanently audit-logged.
          </div>

          <div>
            <label
              htmlFor="killswitch-reason"
              className="block font-title text-sm font-semibold text-ink"
            >
              Reason (required, min {MIN_REASON_LENGTH} characters)
            </label>
            <textarea
              id="killswitch-reason"
              rows={3}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g. CSO §29 complaint received — legal advised immediate disable pending review"
              className="mt-s2 w-full resize-y rounded-md border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
            />
            {reason.length > 0 && !reasonValid ? (
              <p className="mt-s1 text-xs text-danger">
                {MIN_REASON_LENGTH - reason.trim().length} more character
                {MIN_REASON_LENGTH - reason.trim().length === 1 ? "" : "s"}{" "}
                required.
              </p>
            ) : null}
          </div>

          <div>
            <label
              htmlFor="killswitch-lawyer"
              className="block font-title text-sm font-semibold text-ink"
            >
              Lawyer reference (optional)
            </label>
            <input
              id="killswitch-lawyer"
              type="text"
              value={lawyerReference}
              onChange={(e) => setLawyerReference(e.target.value)}
              placeholder="e.g. Barrister Karim · Memo 2026-05-22"
              className="mt-s2 w-full rounded-md border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
            />
          </div>

          <div>
            <label
              htmlFor="killswitch-mfa"
              className="flex items-center gap-s2 font-title text-sm font-semibold text-ink"
            >
              <Lock size={14} className="text-muted" aria-hidden />
              MFA re-confirmation (6-digit code)
            </label>
            <input
              id="killswitch-mfa"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              value={mfaCode}
              onChange={(e) =>
                setMfaCode(e.target.value.replace(/\D/g, "").slice(0, 6))
              }
              placeholder="123456"
              className="mt-s2 w-full rounded-md border border-line bg-card px-s3 py-s2 text-center font-mono text-lg tracking-[0.4em] text-ink placeholder:tracking-normal placeholder:text-muted focus:border-sage focus:outline-none"
            />
            <p className="mt-s1 text-xs text-muted">
              A fresh code is required even though you are already signed in.
            </p>
          </div>

          {toggle.isError ? (
            <p role="alert" className="text-sm text-danger">
              Could not toggle the kill-switch. The MFA code may be invalid or
              expired — check your authenticator and try again.
            </p>
          ) : null}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line bg-cream px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant="danger"
            onClick={() => toggle.mutate()}
            disabled={!canConfirm}
          >
            {toggle.isPending ? "Applying…" : "Confirm with MFA →"}
          </Button>
        </footer>
      </div>
    </div>
  );
}
