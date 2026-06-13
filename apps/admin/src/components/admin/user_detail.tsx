"use client";

import { useState } from "react";
import {
  useQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
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
  fetchUserDetail,
  suspendUser,
  reactivateUser,
  upgradeSubscription,
  userDetailQueryKey,
  type AdminUserDetail,
  type AdminSubscription,
  type AdminUsage,
  type AdminAuditTrailRow,
  type AdminUserRow,
} from "@/lib/api/users";
import {
  fetchPricingTiers,
  pricingTiersQueryKey,
  type PricingTier,
} from "@/lib/api/pricing";
import { BILLING_CYCLES } from "@/types/enums";

/**
 * User detail + actions client island — EPIC-12.T-008.
 *
 * Loads `GET /admin/api/users/{id}` (T-003) via TanStack Query and lays out the
 * profile, subscription, usage, and recent admin audit-trail sections (Admin
 * Portal spec §4.2). The action buttons (suspend / reactivate / manual upgrade)
 * are gated on `canWrite` (ops + super; support is read-only) and each opens a
 * confirm dialog. Suspend + upgrade require a non-blank reason; on success the
 * detail query is invalidated so the status badge flips to "Suspended"
 * immediately (spec §15). The server page enforces the role guard before this
 * island ever mounts.
 */

export interface UserDetailProps {
  id: string;
  /** Whether the viewer may run suspend/reactivate/upgrade actions. */
  canWrite: boolean;
}

export function UserDetail({ id, canWrite }: UserDetailProps) {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: userDetailQueryKey(id),
    queryFn: () => fetchUserDetail(id),
  });

  if (isPending) {
    return (
      <Card className="h-64 animate-pulse" aria-busy aria-label="Loading user" />
    );
  }

  if (isError) {
    return (
      <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
        <CardTitle>Could not load user</CardTitle>
        <CardDescription>
          The user-detail request failed. Check your connection and try again.
        </CardDescription>
        <Button variant="primary" onClick={() => void refetch()}>
          Retry
        </Button>
      </Card>
    );
  }

  return <UserDetailView id={id} detail={data} canWrite={canWrite} />;
}

type ActiveDialog = "suspend" | "reactivate" | "upgrade" | null;

function UserDetailView({
  id,
  detail,
  canWrite,
}: {
  id: string;
  detail: AdminUserDetail;
  canWrite: boolean;
}) {
  const queryClient = useQueryClient();
  const [dialog, setDialog] = useState<ActiveDialog>(null);

  const refresh = () =>
    void queryClient.invalidateQueries({ queryKey: userDetailQueryKey(id) });

  const { user } = detail;

  return (
    <div className="space-y-s6">
      <header className="flex flex-wrap items-start justify-between gap-s4">
        <div>
          <div className="flex items-center gap-s3">
            <h1 className="font-title text-2xl font-bold text-ink">
              {user.name || "(no name)"}
            </h1>
            <Chip tone={user.is_active ? "sage" : "danger"}>
              {user.is_active ? "Active" : "Suspended"}
            </Chip>
          </div>
          <p className="mt-s1 font-mono text-sm text-muted">
            {user.masked_phone} · account #{String(user.id)}
          </p>
        </div>

        {canWrite ? (
          <div className="flex flex-wrap items-center gap-s3">
            {user.is_active ? (
              <Button variant="danger" onClick={() => setDialog("suspend")}>
                Suspend
              </Button>
            ) : (
              <Button
                variant="secondary"
                onClick={() => setDialog("reactivate")}
              >
                Reactivate
              </Button>
            )}
            <Button variant="primary" onClick={() => setDialog("upgrade")}>
              Upgrade subscription
            </Button>
          </div>
        ) : null}
      </header>

      <div className="grid gap-s5 md:grid-cols-2">
        <ProfileSection user={user} />
        <SubscriptionSection subscription={detail.subscription} />
        <UsageSection usage={detail.usage} />
      </div>

      <AuditTrailSection rows={detail.audit_trail} />

      {dialog === "suspend" ? (
        <SuspendDialog
          id={id}
          onClose={() => setDialog(null)}
          onDone={refresh}
        />
      ) : null}
      {dialog === "reactivate" ? (
        <ReactivateDialog
          id={id}
          onClose={() => setDialog(null)}
          onDone={refresh}
        />
      ) : null}
      {dialog === "upgrade" ? (
        <UpgradeDialog
          id={id}
          onClose={() => setDialog(null)}
          onDone={refresh}
        />
      ) : null}
    </div>
  );
}

function ProfileSection({ user }: { user: AdminUserRow }) {
  return (
    <Card className="space-y-s3">
      <CardTitle>Profile</CardTitle>
      <dl className="grid grid-cols-2 gap-x-s4 gap-y-s3 text-sm">
        <Field label="Name" value={user.name || "—"} />
        <Field label="Phone" value={user.masked_phone} mono />
        <Field label="Role" value={user.role} capitalize />
        <Field label="Language" value={user.language.toUpperCase()} />
        <Field label="Created" value={formatDate(user.created_at)} />
        <Field
          label="Last login"
          value={user.last_login_at ? formatDate(user.last_login_at) : "Never"}
        />
      </dl>
    </Card>
  );
}

function SubscriptionSection({
  subscription,
}: {
  subscription: AdminSubscription | null;
}) {
  return (
    <Card className="space-y-s3">
      <CardTitle>Subscription</CardTitle>
      {subscription === null ? (
        <CardDescription>
          No active subscription on record for this account.
        </CardDescription>
      ) : (
        <dl className="grid grid-cols-2 gap-x-s4 gap-y-s3 text-sm">
          <Field label="Tier" value={subscription.tier_label} />
          <Field
            label="Status"
            value={subscription.status}
            capitalize
          />
          <Field
            label="Billing cycle"
            value={subscription.billing_cycle}
            capitalize
          />
          <Field
            label="Next billing"
            value={
              subscription.next_billing_at
                ? formatDate(subscription.next_billing_at)
                : "—"
            }
          />
          <Field
            label="Started"
            value={
              subscription.start_at ? formatDate(subscription.start_at) : "—"
            }
          />
        </dl>
      )}
    </Card>
  );
}

function UsageSection({ usage }: { usage: AdminUsage }) {
  return (
    <Card className="space-y-s3">
      <CardTitle>Usage</CardTitle>
      <dl className="grid grid-cols-3 gap-s4 text-sm">
        <Stat label="Buildings" value={usage.buildings} />
        <Stat label="Tenants" value={usage.tenant_profiles} />
        <Stat label="Subscriptions" value={usage.subscriptions} />
      </dl>
    </Card>
  );
}

function AuditTrailSection({ rows }: { rows: AdminAuditTrailRow[] }) {
  return (
    <Card className="space-y-s4">
      <div>
        <CardTitle>Audit trail</CardTitle>
        <CardDescription>
          Recent admin actions involving this account (newest first).
        </CardDescription>
      </div>

      {rows.length === 0 ? (
        <p className="text-sm text-muted">No admin actions recorded yet.</p>
      ) : (
        <Table aria-label="Audit trail">
          <TableHead>
            <TableRow>
              <TableHeaderCell>When</TableHeaderCell>
              <TableHeaderCell>Action</TableHeaderCell>
              <TableHeaderCell>Reason</TableHeaderCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => (
              <TableRow key={String(row.id)}>
                <TableCell className="whitespace-nowrap text-xs text-muted">
                  {formatDate(row.created_at)}
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {row.action}
                </TableCell>
                <TableCell className="text-sm text-mutedDk">
                  {row.reason || "—"}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </Card>
  );
}

/* --------------------------------- dialogs -------------------------------- */

function SuspendDialog({
  id,
  onClose,
  onDone,
}: {
  id: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const [reason, setReason] = useState("");
  const mutation = useMutation<AdminUserRow, Error, void>({
    mutationFn: () => suspendUser(id, reason.trim()),
    onSuccess: () => {
      onDone();
      onClose();
    },
  });
  const reasonMissing = reason.trim().length === 0;

  return (
    <ConfirmDialog
      title="Suspend account"
      label="Suspend account"
      description="The user will be logged out of all devices and cannot sign in until reactivated."
      confirmText="Suspend"
      confirmVariant="danger"
      confirmDisabled={reasonMissing || mutation.isPending}
      pending={mutation.isPending}
      error={
        mutation.isError ? "Could not suspend the account. Try again." : null
      }
      onClose={onClose}
      onConfirm={() => mutation.mutate()}
    >
      <ReasonField
        required
        value={reason}
        onChange={setReason}
        placeholder="e.g. Confirmed fraudulent activity — ticket #1234"
      />
    </ConfirmDialog>
  );
}

function ReactivateDialog({
  id,
  onClose,
  onDone,
}: {
  id: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const [reason, setReason] = useState("");
  const mutation = useMutation<AdminUserRow, Error, void>({
    mutationFn: () => reactivateUser(id, reason.trim()),
    onSuccess: () => {
      onDone();
      onClose();
    },
  });

  return (
    <ConfirmDialog
      title="Reactivate account"
      label="Reactivate account"
      description="The user will be able to sign in again immediately."
      confirmText="Reactivate"
      confirmVariant="primary"
      confirmDisabled={mutation.isPending}
      pending={mutation.isPending}
      error={
        mutation.isError ? "Could not reactivate the account. Try again." : null
      }
      onClose={onClose}
      onConfirm={() => mutation.mutate()}
    >
      <ReasonField
        value={reason}
        onChange={setReason}
        placeholder="Optional — context for the audit log"
      />
    </ConfirmDialog>
  );
}

function UpgradeDialog({
  id,
  onClose,
  onDone,
}: {
  id: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const tiers = useQuery({
    queryKey: pricingTiersQueryKey,
    queryFn: fetchPricingTiers,
  });
  const [tierId, setTierId] = useState<string>("");
  const [billingCycle, setBillingCycle] = useState<string>("monthly");
  const [reason, setReason] = useState("");

  const mutation = useMutation<AdminSubscription, Error, void>({
    mutationFn: () =>
      upgradeSubscription(id, {
        tierId: Number(tierId),
        billingCycle,
        reason: reason.trim(),
      }),
    onSuccess: () => {
      onDone();
      onClose();
    },
  });

  const reasonMissing = reason.trim().length === 0;
  const tierMissing = tierId === "";

  return (
    <ConfirmDialog
      title="Upgrade subscription"
      label="Upgrade subscription"
      description="Manually move this user onto a different tier. This overrides their current plan and is audit-logged."
      confirmText="Apply upgrade"
      confirmVariant="primary"
      confirmDisabled={
        reasonMissing || tierMissing || mutation.isPending || tiers.isPending
      }
      pending={mutation.isPending}
      error={
        mutation.isError
          ? "Could not upgrade the subscription. A reason and tier are required."
          : null
      }
      onClose={onClose}
      onConfirm={() => mutation.mutate()}
    >
      <div className="space-y-s4">
        <label className="block">
          <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
            Tier
          </span>
          <select
            aria-label="Tier"
            value={tierId}
            onChange={(e) => setTierId(e.target.value)}
            disabled={tiers.isPending || tiers.isError}
            className="mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink focus:border-sage focus:outline-none"
          >
            <option value="">
              {tiers.isError ? "Could not load tiers" : "Select a tier…"}
            </option>
            {(tiers.data ?? []).map((tier: PricingTier) => (
              <option key={tier.key} value={String(tier.id)}>
                {tier.label}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
            Billing cycle
          </span>
          <select
            aria-label="Billing cycle"
            value={billingCycle}
            onChange={(e) => setBillingCycle(e.target.value)}
            className="mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm capitalize text-ink focus:border-sage focus:outline-none"
          >
            {BILLING_CYCLES.map((cycle) => (
              <option key={cycle} value={cycle}>
                {cycle}
              </option>
            ))}
          </select>
        </label>

        <ReasonField
          required
          value={reason}
          onChange={setReason}
          placeholder="e.g. Goodwill upgrade — support escalation #4567"
        />
      </div>
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

function Field({
  label,
  value,
  mono = false,
  capitalize = false,
}: {
  label: string;
  value: string;
  mono?: boolean;
  capitalize?: boolean;
}) {
  return (
    <div>
      <dt className="text-xs font-semibold uppercase tracking-wide text-muted">
        {label}
      </dt>
      <dd
        className={[
          "mt-s1 text-ink",
          mono ? "font-mono text-xs" : "",
          capitalize ? "capitalize" : "",
        ]
          .filter(Boolean)
          .join(" ")}
      >
        {value}
      </dd>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div>
      <dt className="text-xs font-semibold uppercase tracking-wide text-muted">
        {label}
      </dt>
      <dd className="mt-s1 font-title text-xl font-bold text-ink">{value}</dd>
    </div>
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
