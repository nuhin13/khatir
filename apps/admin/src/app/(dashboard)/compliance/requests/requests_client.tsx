"use client";

import { DataRequestQueue } from "@/components/admin/data_request_queue";

/**
 * Data-request queue client wrapper — EPIC-16.T-008.
 *
 * Thin boundary that mounts the interactive {@link DataRequestQueue} island
 * (pending queue with SLA badges + approve/reject dialog, plus a completed
 * history tab). The route's compliance+super role guard lives in the server
 * `page.tsx`; this component assumes it has already passed.
 */
export function DataRequestsClient() {
  return <DataRequestQueue />;
}
