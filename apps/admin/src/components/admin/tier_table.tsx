"use client";

import { useState } from "react";
import { Check, Pencil, X } from "lucide-react";
import {
  useMutation,
  useQueryClient,
  type UseMutationResult,
} from "@tanstack/react-query";
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
  ImpactPreviewModal,
  type TierImpact,
} from "@/components/admin/impact_preview_modal";
import {
  editTier,
  previewTier,
  pricingTiersQueryKey,
  type PricingTier,
  type TierChanges,
  type TierImpactResponse,
} from "@/lib/api/pricing";

/**
 * Editable pricing-tier table — EPIC-12.T-005.
 *
 * Mirrors the "Pricing tiers" table + "Edit tier" flow in `KhatirAdmin.jsx`
 * (Admin Portal spec §4.3.1): each tier is a row; the pencil opens an inline
 * editor; "Preview impact" calls the read-only T-001 preview endpoint; a
 * confirmation surface (the reusable {@link ImpactPreviewModal} from T-006)
 * shows subscribers affected + revenue delta and requires a non-blank reason
 * before applying. On apply, the list is refetched after a short delay so the
 * cache-busted public catalogue (≤60s) is reflected.
 *
 * Presentation-only styling comes from Notun Din token classes; no hardcoded
 * hex/px. The table is fed a validated tier list by the page.
 */

export interface TierTableProps {
  tiers: PricingTier[];
}

/** A blank-friendly number → string for editable text inputs. */
function numStr(value: number | null): string {
  return value === null ? "" : String(value);
}

function priceLabel(price: string | null): string {
  if (price === null) return "—";
  const n = Number(price);
  if (Number.isNaN(n)) return "৳" + price;
  if (n === 0) return "FREE";
  return "৳" + n.toLocaleString();
}

/** Editable draft of a tier (strings for numeric inputs to allow blanks). */
interface Draft {
  label: string;
  label_bn: string;
  tenant_min: string;
  tenant_max: string;
  monthly_price: string;
  annual_price: string;
  includes_verification: boolean;
  included_credits: string;
  active: boolean;
  sort_order: string;
}

function toDraft(tier: PricingTier): Draft {
  return {
    label: tier.label,
    label_bn: tier.label_bn,
    tenant_min: String(tier.tenant_min),
    tenant_max: numStr(tier.tenant_max),
    monthly_price: tier.monthly_price ?? "",
    annual_price: tier.annual_price ?? "",
    includes_verification: tier.includes_verification,
    included_credits: String(tier.included_credits),
    active: tier.active,
    sort_order: String(tier.sort_order),
  };
}

/** The proposed change body sent to preview/edit (only changed fields). */
function toChanges(draft: Draft): TierChanges {
  const intOrNull = (v: string): number | null =>
    v.trim() === "" ? null : Math.trunc(Number(v));
  const priceOrNull = (v: string): string | null =>
    v.trim() === "" ? null : String(Number(v));
  return {
    label: draft.label,
    label_bn: draft.label_bn,
    tenant_min: Math.trunc(Number(draft.tenant_min)),
    tenant_max: intOrNull(draft.tenant_max),
    monthly_price: priceOrNull(draft.monthly_price),
    annual_price: priceOrNull(draft.annual_price),
    includes_verification: draft.includes_verification,
    included_credits: Math.trunc(Number(draft.included_credits)),
    active: draft.active,
    sort_order: Math.trunc(Number(draft.sort_order)),
  };
}

/** Build the presentational impact payload the T-006 modal expects. */
function toImpact(
  tier: PricingTier,
  draft: Draft,
  preview: TierImpactResponse,
): TierImpact {
  return {
    tierLabel: tier.label,
    tierKey: tier.key,
    oldMonthly: Number(tier.monthly_price ?? 0),
    newMonthly: Number(draft.monthly_price === "" ? 0 : draft.monthly_price),
    // The backend computes the precise revenue delta across billing cycles; the
    // modal recomputes a simple monthly figure from old/new × subscribers for
    // display, so we surface the authoritative subscriber count here.
    subscribersAffected: preview.subscribers_affected,
    oldIncludesVerification: tier.includes_verification,
    newIncludesVerification: draft.includes_verification,
  };
}

const REFETCH_DELAY_MS = 2000;

export function TierTable({ tiers }: TierTableProps) {
  const [editingKey, setEditingKey] = useState<string | null>(null);

  return (
    <div className="overflow-hidden rounded-card border border-line bg-card shadow-sm">
      <div className="flex items-center justify-between border-b border-line px-s5 py-s4">
        <div>
          <h2 className="font-title text-base font-bold text-ink">
            Pricing tiers
          </h2>
          <p className="mt-s1 text-xs text-muted">
            {tiers.length} tier{tiers.length === 1 ? "" : "s"} · live-configurable
            · every change is audit-logged
          </p>
        </div>
      </div>

      <Table className="rounded-none border-0">
        <TableHead>
          <TableRow>
            <TableHeaderCell>Tier</TableHeaderCell>
            <TableHeaderCell>Tenants</TableHeaderCell>
            <TableHeaderCell className="text-right">Monthly</TableHeaderCell>
            <TableHeaderCell className="text-right">Annual</TableHeaderCell>
            <TableHeaderCell className="text-right">
              Verification
            </TableHeaderCell>
            <TableHeaderCell className="text-right">Active</TableHeaderCell>
            <TableHeaderCell className="text-right">
              <span className="sr-only">Edit</span>
            </TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {tiers.map((tier) => (
            <TableRow key={tier.key}>
              <TableCell>
                <div className="font-title text-sm font-bold text-ink">
                  {tier.label}
                </div>
                <div className="mt-s1 text-xs text-muted">
                  {tier.label_bn} ·{" "}
                  <span className="font-mono">{tier.key}</span>
                </div>
              </TableCell>
              <TableCell>
                <span className="font-mono text-xs text-mutedDk">
                  {tier.tenant_min}–{tier.tenant_max ?? "∞"}
                </span>
              </TableCell>
              <TableCell className="text-right font-mono font-bold text-ink">
                {priceLabel(tier.monthly_price)}
              </TableCell>
              <TableCell className="text-right font-mono text-xs text-muted">
                {priceLabel(tier.annual_price)}
              </TableCell>
              <TableCell className="text-right">
                {tier.includes_verification ? (
                  <Chip tone="sage">{tier.included_credits} credits</Chip>
                ) : (
                  <Chip tone="neutral">None</Chip>
                )}
              </TableCell>
              <TableCell className="text-right">
                {tier.active ? (
                  <Chip tone="sage">Active</Chip>
                ) : (
                  <Chip tone="neutral">Inactive</Chip>
                )}
              </TableCell>
              <TableCell className="text-right">
                <button
                  type="button"
                  aria-label={"Edit " + tier.label}
                  onClick={() => setEditingKey(tier.key)}
                  className="rounded-button p-s2 text-muted hover:bg-sageBg"
                >
                  <Pencil size={15} aria-hidden />
                </button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {editingKey !== null ? (
        <TierEditor
          tier={tiers.find((t) => t.key === editingKey)!}
          onClose={() => setEditingKey(null)}
        />
      ) : null}
    </div>
  );
}

interface TierEditorProps {
  tier: PricingTier;
  onClose: () => void;
}

/** The inline-edit modal: form fields, preview, reason, confirm. */
function TierEditor({ tier, onClose }: TierEditorProps) {
  const queryClient = useQueryClient();
  const [draft, setDraft] = useState<Draft>(() => toDraft(tier));
  const [reason, setReason] = useState("");
  const [confirming, setConfirming] = useState(false);

  const preview = useMutation<TierImpactResponse, Error, void>({
    mutationFn: () => previewTier(tier.key, toChanges(draft)),
    onSuccess: () => setConfirming(true),
  });

  const apply: UseMutationResult<PricingTier, Error, void> = useMutation({
    mutationFn: () => editTier(tier.key, toChanges(draft), reason.trim()),
    onSuccess: () => {
      // Cache is busted server-side; refetch shortly after so the table (and
      // the public catalogue) reflect the change within ~60s.
      setTimeout(() => {
        void queryClient.invalidateQueries({ queryKey: pricingTiersQueryKey });
      }, REFETCH_DELAY_MS);
      onClose();
    },
  });

  const set = <K extends keyof Draft>(field: K, value: Draft[K]) =>
    setDraft((d) => ({ ...d, [field]: value }));

  const impact =
    preview.data !== undefined
      ? toImpact(tier, draft, preview.data)
      : undefined;
  const reasonMissing = reason.trim().length === 0;

  return (
    <>
      <div
        role="presentation"
        onClick={onClose}
        className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-ink/40 p-s4"
      >
        <div
          role="dialog"
          aria-modal="true"
          aria-label={"Edit tier " + tier.label}
          onClick={(e) => e.stopPropagation()}
          className="my-s6 w-full max-w-xl overflow-hidden rounded-card bg-card shadow-lg"
        >
          <header className="flex items-center justify-between border-b border-line px-s5 py-s4">
            <div>
              <h2 className="font-title text-base font-extrabold text-ink">
                Edit tier · {tier.label}
              </h2>
              <p className="mt-s1 font-mono text-xs text-muted">{tier.key}</p>
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

          <div className="space-y-s4 px-s5 py-s5">
            <div className="grid grid-cols-2 gap-s4">
              <TextField
                label="Label (EN)"
                value={draft.label}
                onChange={(v) => set("label", v)}
              />
              <TextField
                label="Label (BN)"
                value={draft.label_bn}
                onChange={(v) => set("label_bn", v)}
              />
              <TextField
                label="Min tenants"
                type="number"
                value={draft.tenant_min}
                onChange={(v) => set("tenant_min", v)}
              />
              <TextField
                label="Max tenants"
                type="number"
                placeholder="∞ leave blank"
                value={draft.tenant_max}
                onChange={(v) => set("tenant_max", v)}
              />
              <TextField
                label="Monthly (BDT)"
                type="number"
                value={draft.monthly_price}
                onChange={(v) => set("monthly_price", v)}
              />
              <TextField
                label="Annual (BDT)"
                type="number"
                placeholder="leave blank if N/A"
                value={draft.annual_price}
                onChange={(v) => set("annual_price", v)}
              />
              <TextField
                label="Credits"
                type="number"
                value={draft.included_credits}
                onChange={(v) => set("included_credits", v)}
              />
              <TextField
                label="Sort order"
                type="number"
                value={draft.sort_order}
                onChange={(v) => set("sort_order", v)}
              />
            </div>

            <div className="flex items-center gap-s5">
              <label className="flex items-center gap-s2 text-sm text-mutedDk">
                <Toggle
                  checked={draft.includes_verification}
                  onChange={(v) => set("includes_verification", v)}
                  label="Includes verification"
                />
                Includes verification
              </label>
              <label className="flex items-center gap-s2 text-sm text-mutedDk">
                <Toggle
                  checked={draft.active}
                  onChange={(v) => set("active", v)}
                  label="Active"
                />
                Active
              </label>
            </div>

            <div>
              <label
                htmlFor="tier-reason"
                className="block text-xs font-semibold uppercase tracking-wide text-muted"
              >
                Reason for change (required)
              </label>
              <textarea
                id="tier-reason"
                rows={2}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="e.g. Q3 pricing review — competitor parity adjustment"
                className="mt-s2 w-full resize-y rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
              />
            </div>

            {preview.isError ? (
              <p role="alert" className="text-sm text-roseDk">
                Could not compute the impact preview. Try again.
              </p>
            ) : null}
            {apply.isError ? (
              <p role="alert" className="text-sm text-roseDk">
                Could not apply the change. A reason is required and the change
                must be valid.
              </p>
            ) : null}
          </div>

          <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
            <Button variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={() => preview.mutate()}
              disabled={reasonMissing || preview.isPending}
            >
              <Check size={15} aria-hidden />
              {preview.isPending ? "Computing…" : "Preview impact"}
            </Button>
          </footer>
        </div>
      </div>

      <ImpactPreviewModal
        open={confirming}
        impact={impact}
        loading={preview.isPending}
        onClose={() => setConfirming(false)}
        onConfirm={() => apply.mutate()}
        confirmDisabled={reasonMissing || apply.isPending}
      />
    </>
  );
}

interface TextFieldProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: "text" | "number";
  placeholder?: string;
}

function TextField({
  label,
  value,
  onChange,
  type = "text",
  placeholder,
}: TextFieldProps) {
  return (
    <label className="block">
      <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
        {label}
      </span>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-s2 w-full rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
      />
    </label>
  );
}
