"use client";

import { useState } from "react";
import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from "@/components/ui/table";
import {
  fetchRefunds,
  processRefund,
  refundsQueryKey,
  type RefundRequest,
  type RefundDecision,
} from "@/lib/api/refunds";

/**
 * Refund queue client island — EPIC-12.T-009.
 *
 * Loads `GET /admin/api/billing/refunds` (T-004) via TanStack Query and renders
 * the pending payment intents as a table: user, tier, billing cycle, provider,
 * and date. Each row offers Approve / Deny actions that open a confirm dialog;
 * a denial requires a non-blank reason (re-checked server-side). On success the
 * queue query is invalidated so the processed row drops out immediately. The
 * server page enforces the finance+super role guard before this island mounts.
 */
export function RefundQueue() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: refundsQueryKey,
    queryFn: fetchRefunds,
  });

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Refunds</h1>
        <p className="mt-s1 text-sm text-muted">
          Pending refund requests awaiting a finance decision. Approving cancels
          the subscription; both decisions are audit-logged.
        </p>
      </div>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading refunds"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load refunds</CardTitle>
          <CardDescription>
            The refund-queue request failed. Check your connection and try
            again.
          </CardDescription>
          <Button variant="primary" onClick={() => void refetch()}>
            Retry
          </Button>
        </Card>
      ) : (
        <RefundTable rows={data} />
      )}
    </div>
  );
}

function RefundTable({ rows }: { rows: RefundRequest[] }) {
  const queryClient = useQueryClient();
  const [active, setActive] = useState<{
    row: RefundRequest;
    approve: boolean;
  } | null>(null);

  const refresh = () =>
    void queryClient.invalidateQueries({ queryKey: refundsQueryKey });

  if (rows.length === 0) {
    return (
      <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
        <CardTitle>No pending refunds</CardTitle>
        <CardDescription>
          There are no refund requests awaiting a decision right now.
        </CardDescription>
      </Card>
    );
  }

  return (
    <>
      <Table aria-label="Refund queue">
        <TableHead>
          <TableRow>
            <TableHeaderCell>User</TableHeaderCell>
            <TableHeaderCell>Tier</TableHeaderCell>
            <TableHeaderCell>Cycle</TableHeaderCell>
            <TableHeaderCell>Provider</TableHeaderCell>
            <TableHeaderCell>Requested</TableHeaderCell>
            <TableHeaderCell className="text-right">Actions</TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={String(row.id)}>
              <TableCell className="font-mono text-xs">
                {row.user_id !== null ? `#${String(row.user_id)}` : "—"}
              </TableCell>
              <TableCell className="capitalize">{row.tier_key ?? "—"}</TableCell>
              <TableCell className="capitalize">
                {row.billing_cycle ?? "—"}
              </TableCell>
              <TableCell className="capitalize">{row.provider ?? "—"}</TableCell>
              <TableCell className="whitespace-nowrap text-xs text-muted">
                {formatDate(row.created_at)}
              </TableCell>
              <TableCell>
                <div className="flex items-center justify-end gap-s2">
                  <Button
                    variant="primary"
                    className="px-s4 py-s2"
                    onClick={() => setActive({ row, approve: true })}
                  >
                    Approve
                  </Button>
                  <Button
                    variant="danger"
                    className="px-s4 py-s2"
                    onClick={() => setActive({ row, approve: false })}
                  >
                    Deny
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {active ? (
        <ProcessDialog
          row={active.row}
          approve={active.approve}
          onClose={() => setActive(null)}
          onDone={refresh}
        />
      ) : null}
    </>
  );
}

function ProcessDialog({
  row,
  approve,
  onClose,
  onDone,
}: {
  row: RefundRequest;
  approve: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const [reason, setReason] = useState("");
  const mutation = useMutation<RefundDecision, Error, void>({
    mutationFn: () =>
      processRefund(row.id, { approve, reason: reason.trim() }),
    onSuccess: () => {
      onDone();
      onClose();
    },
  });

  // Reason is mandatory to deny; optional (but recorded) to approve.
  const reasonMissing = !approve && reason.trim().length === 0;

  return (
    <ConfirmDialog
      title={approve ? "Approve refund" : "Deny refund"}
      label={approve ? "Approve refund" : "Deny refund"}
      description={
        approve
          ? "Record this refund as processed and cancel the linked subscription. This is audit-logged."
          : "Reject this refund request. The subscription is left untouched. A reason is required and audit-logged."
      }
      confirmText={approve ? "Approve" : "Deny"}
      confirmVariant={approve ? "primary" : "danger"}
      confirmDisabled={reasonMissing || mutation.isPending}
      pending={mutation.isPending}
      error={
        mutation.isError
          ? approve
            ? "Could not approve the refund. Try again."
            : "Could not deny the refund. A reason is required."
          : null
      }
      onClose={onClose}
      onConfirm={() => mutation.mutate()}
    >
      <ReasonField
        required={!approve}
        value={reason}
        onChange={setReason}
        placeholder={
          approve
            ? "Optional — context for the audit log"
            : "e.g. Outside the refund window — ticket #1234"
        }
      />
    </ConfirmDialog>
  );
}

/* ------------------------------ shared bits ------------------------------- */

interface ConfirmDialogProps {
  title: string;
  /** aria-label for the dialog element (test + a11y hook). */
  label: string;
  description: string;
  confirmText: string;
  confirmVariant: "primary" | "danger";
  confirmDisabled: boolean;
  pending: boolean;
  error: string | null;
  onClose: () => void;
  onConfirm: () => void;
  children: React.ReactNode;
}

function ConfirmDialog({
  title,
  label,
  description,
  confirmText,
  confirmVariant,
  confirmDisabled,
  pending,
  error,
  onClose,
  onConfirm,
  children,
}: ConfirmDialogProps) {
  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-ink/40 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={label}
        onClick={(e) => e.stopPropagation()}
        className="my-s6 w-full max-w-md overflow-hidden rounded-card bg-card shadow-lg"
      >
        <header className="border-b border-line px-s5 py-s4">
          <h2 className="font-title text-base font-extrabold text-ink">
            {title}
          </h2>
          <p className="mt-s1 text-sm text-muted">{description}</p>
        </header>

        <div className="space-y-s4 px-s5 py-s5">
          {children}
          {error ? (
            <p role="alert" className="text-sm text-roseDk">
              {error}
            </p>
          ) : null}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={confirmVariant}
            onClick={onConfirm}
            disabled={confirmDisabled}
          >
            {pending ? "Working…" : confirmText}
          </Button>
        </footer>
      </div>
    </div>
  );
}

function ReasonField({
  value,
  onChange,
  placeholder,
  required = false,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
        Reason{required ? " (required)" : " (optional)"}
      </span>
      <textarea
        aria-label="Reason"
        rows={2}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-s2 w-full resize-y rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
      />
    </label>
  );
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
