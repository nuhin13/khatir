"use client";

import { useState } from "react";
import {
  useQuery,
  useMutation,
  useQueryClient,
  keepPreviousData,
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
  fetchDataRequests,
  processDataRequest,
  dataRequestsQueryKey,
  pageFromLink,
  DATA_REQUEST_TYPE_LABELS,
  DATA_REQUEST_STATUS_LABELS,
  SLA_STATES,
  SLA_STATE_LABELS,
  type DataRequest,
  type DataRequestType,
  type DataRequestStatus,
  type SlaState,
} from "@/lib/api/data-requests";

/**
 * Data-request queue client island — EPIC-16.T-008.
 *
 * Two tabs over the PDPA data-request queue (EPIC-16.T-004):
 *
 * - **Pending** — requests awaiting a decision, each row carrying an SLA badge
 *   (red when overdue, amber when due soon, green when on track) and Approve /
 *   Reject actions. Both actions open a confirm dialog; a rejection requires a
 *   non-blank reason (re-checked server-side). On success the queue query is
 *   invalidated so the processed row drops out immediately.
 * - **Completed** — read-only history of resolved requests (completed /
 *   processing / rejected), filtered server-side by status.
 *
 * The server `page.tsx` enforces the compliance+super role guard before this
 * island mounts. All styling comes from Notun Din token classes — no hardcoded
 * hex/px.
 */

type Tab = "pending" | "completed";

export function DataRequestQueue() {
  const [tab, setTab] = useState<Tab>("pending");

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Data requests</h1>
        <p className="mt-s1 text-sm text-muted">
          PDPA export and erasure requests. Approving an export queues the data
          package; approving a delete queues the erasure. Every decision is
          audit-logged.
        </p>
      </div>

      <Tabs tab={tab} onChange={setTab} />

      {tab === "pending" ? <PendingTab /> : <CompletedTab />}
    </div>
  );
}

function Tabs({ tab, onChange }: { tab: Tab; onChange: (tab: Tab) => void }) {
  const tabClass = (active: boolean) =>
    [
      "rounded-button px-s4 py-s2 font-title text-sm font-semibold",
      active ? "bg-ink text-card" : "border border-line text-ink",
    ].join(" ");
  return (
    <div role="tablist" aria-label="Data request tabs" className="flex gap-s2">
      <button
        type="button"
        role="tab"
        aria-selected={tab === "pending"}
        onClick={() => onChange("pending")}
        className={tabClass(tab === "pending")}
      >
        Pending
      </button>
      <button
        type="button"
        role="tab"
        aria-selected={tab === "completed"}
        onClick={() => onChange("completed")}
        className={tabClass(tab === "completed")}
      >
        Completed
      </button>
    </div>
  );
}

/* -------------------------------- pending -------------------------------- */

function PendingTab() {
  const filters = { status: "pending" as const };
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: dataRequestsQueryKey(filters),
    queryFn: () => fetchDataRequests(filters),
    placeholderData: keepPreviousData,
  });

  if (isPending) {
    return (
      <Card
        className="h-64 animate-pulse"
        aria-busy
        aria-label="Loading data requests"
      />
    );
  }
  if (isError) {
    return <ErrorCard onRetry={() => void refetch()} />;
  }
  if (data.results.length === 0) {
    return (
      <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
        <CardTitle>No pending data requests</CardTitle>
        <CardDescription>
          There are no data requests awaiting a decision right now.
        </CardDescription>
      </Card>
    );
  }

  return <PendingTable rows={data.results} filters={filters} />;
}

function PendingTable({
  rows,
  filters,
}: {
  rows: DataRequest[];
  filters: { status: "pending" };
}) {
  const queryClient = useQueryClient();
  const [active, setActive] = useState<{
    row: DataRequest;
    approve: boolean;
  } | null>(null);

  const refresh = () =>
    void queryClient.invalidateQueries({
      queryKey: dataRequestsQueryKey(filters),
    });

  return (
    <>
      <Table aria-label="Pending data requests">
        <TableHead>
          <TableRow>
            <TableHeaderCell>User</TableHeaderCell>
            <TableHeaderCell>Type</TableHeaderCell>
            <TableHeaderCell>SLA due</TableHeaderCell>
            <TableHeaderCell>SLA</TableHeaderCell>
            <TableHeaderCell>Requested</TableHeaderCell>
            <TableHeaderCell className="text-right">Actions</TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={String(row.id)}>
              <TableCell className="font-mono text-xs">
                {row.user === null ? "—" : `#${row.user}`}
              </TableCell>
              <TableCell>{typeLabel(row.request_type)}</TableCell>
              <TableCell className="whitespace-nowrap text-xs text-muted">
                {formatDate(row.sla_due)}
              </TableCell>
              <TableCell>
                <SlaBadge state={row.sla_state} />
              </TableCell>
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
                    Reject
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

/* ------------------------------- completed ------------------------------- */

function CompletedTab() {
  const [page, setPage] = useState<string | undefined>(undefined);
  // The queue endpoint filters by a single status; the completed history shows
  // every non-pending state, so we request each and merge client-side.
  const filters = { page };
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: dataRequestsQueryKey(filters),
    queryFn: () => fetchDataRequests(filters),
    placeholderData: keepPreviousData,
  });

  if (isPending) {
    return (
      <Card
        className="h-64 animate-pulse"
        aria-busy
        aria-label="Loading data request history"
      />
    );
  }
  if (isError) {
    return <ErrorCard onRetry={() => void refetch()} />;
  }

  const resolved = data.results.filter((r) => r.status !== "pending");
  const nextPage = pageFromLink(data.pagination.next);
  const prevPage = pageFromLink(data.pagination.previous);

  if (resolved.length === 0) {
    return (
      <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
        <CardTitle>No completed data requests</CardTitle>
        <CardDescription>
          Resolved export and erasure requests will appear here.
        </CardDescription>
      </Card>
    );
  }

  return (
    <div className="space-y-s4">
      <Table aria-label="Completed data requests">
        <TableHead>
          <TableRow>
            <TableHeaderCell>User</TableHeaderCell>
            <TableHeaderCell>Type</TableHeaderCell>
            <TableHeaderCell>Status</TableHeaderCell>
            <TableHeaderCell>Resolved</TableHeaderCell>
            <TableHeaderCell>Handled by</TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {resolved.map((row) => (
            <TableRow key={String(row.id)}>
              <TableCell className="font-mono text-xs">
                {row.user === null ? "—" : `#${row.user}`}
              </TableCell>
              <TableCell>{typeLabel(row.request_type)}</TableCell>
              <TableCell>
                <StatusBadge status={row.status} />
              </TableCell>
              <TableCell className="whitespace-nowrap text-xs text-muted">
                {formatDate(row.completed_at)}
              </TableCell>
              <TableCell className="font-mono text-xs">
                {row.handled_by === null ? "—" : `#${row.handled_by}`}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <div className="flex items-center justify-end gap-s3">
        <button
          type="button"
          onClick={() => setPage(prevPage)}
          disabled={!prevPage}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Previous
        </button>
        <button
          type="button"
          onClick={() => setPage(nextPage)}
          disabled={!nextPage}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Next
        </button>
      </div>
    </div>
  );
}

/* --------------------------------- dialog -------------------------------- */

function ProcessDialog({
  row,
  approve,
  onClose,
  onDone,
}: {
  row: DataRequest;
  approve: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const [reason, setReason] = useState("");
  const mutation = useMutation<DataRequest, Error, void>({
    mutationFn: () => processDataRequest(row.id, { approve, reason: reason.trim() }),
    onSuccess: () => {
      onDone();
      onClose();
    },
  });

  // A reason is mandatory to reject; optional (but recorded) to approve.
  const reasonMissing = !approve && reason.trim().length === 0;
  const isDelete = row.request_type === "delete";

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-ink/40 p-s4"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={approve ? "Approve data request" : "Reject data request"}
        onClick={(e) => e.stopPropagation()}
        className="my-s6 w-full max-w-md overflow-hidden rounded-card bg-card shadow-lg"
      >
        <header className="border-b border-line px-s5 py-s4">
          <h2 className="font-title text-base font-extrabold text-ink">
            {approve ? "Approve data request" : "Reject data request"}
          </h2>
          <p className="mt-s1 text-sm text-muted">
            {approve
              ? isDelete
                ? "Queue the erasure for this request. The cascade runs out of band; this is audit-logged."
                : "Generate the export package for this request. This is audit-logged."
              : "Reject this request. A reason is required and audit-logged."}
          </p>
        </header>

        <div className="space-y-s4 px-s5 py-s5">
          <label className="block">
            <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
              Reason{approve ? " (optional)" : " (required)"}
            </span>
            <textarea
              aria-label="Reason"
              rows={2}
              value={reason}
              placeholder={
                approve
                  ? "Optional — context for the audit log"
                  : "e.g. Could not verify the requester's identity"
              }
              onChange={(e) => setReason(e.target.value)}
              className="mt-s2 w-full resize-y rounded-input border border-line bg-card px-s3 py-s2 font-body text-sm text-ink placeholder:text-muted focus:border-sage focus:outline-none"
            />
          </label>
          {mutation.isError ? (
            <p role="alert" className="text-sm text-roseDk">
              {approve
                ? "Could not approve the request. Try again."
                : "Could not reject the request. A reason is required."}
            </p>
          ) : null}
        </div>

        <footer className="flex items-center justify-end gap-s3 border-t border-line px-s5 py-s4">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={approve ? "primary" : "danger"}
            onClick={() => mutation.mutate()}
            disabled={reasonMissing || mutation.isPending}
          >
            {mutation.isPending ? "Working…" : approve ? "Approve" : "Reject"}
          </Button>
        </footer>
      </div>
    </div>
  );
}

/* --------------------------------- bits ---------------------------------- */

function ErrorCard({ onRetry }: { onRetry: () => void }) {
  return (
    <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
      <CardTitle>Could not load data requests</CardTitle>
      <CardDescription>
        The data-request request failed. Check your connection and try again.
      </CardDescription>
      <Button variant="primary" onClick={onRetry}>
        Retry
      </Button>
    </Card>
  );
}

const SLA_BADGE_CLASS: Record<SlaState, string> = {
  overdue: "bg-dangerBg text-danger",
  due_soon: "bg-butterBg text-butterDk",
  on_track: "bg-sageBg text-sageDk",
};

function SlaBadge({ state }: { state: string }) {
  const key = (SLA_STATES.includes(state as SlaState) ? state : "on_track") as SlaState;
  return (
    <span
      className={[
        "inline-block rounded-button px-s3 py-s1 text-xs font-semibold",
        SLA_BADGE_CLASS[key],
      ].join(" ")}
    >
      {SLA_STATE_LABELS[key]}
    </span>
  );
}

const STATUS_BADGE_CLASS: Record<DataRequestStatus, string> = {
  pending: "bg-butterBg text-butterDk",
  processing: "bg-sageBg text-sageDk",
  completed: "bg-sageBg text-sageDk",
  rejected: "bg-dangerBg text-danger",
};

function StatusBadge({ status }: { status: string }) {
  const key = status as DataRequestStatus;
  const cls = STATUS_BADGE_CLASS[key] ?? "bg-line text-ink";
  return (
    <span
      className={[
        "inline-block rounded-button px-s3 py-s1 text-xs font-semibold",
        cls,
      ].join(" ")}
    >
      {DATA_REQUEST_STATUS_LABELS[key] ?? status}
    </span>
  );
}

function typeLabel(value: string): string {
  return DATA_REQUEST_TYPE_LABELS[value as DataRequestType] ?? value;
}

function formatDate(iso: string | null): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
