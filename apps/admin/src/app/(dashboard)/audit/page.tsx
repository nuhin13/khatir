import { redirect } from "next/navigation";

/**
 * Legacy audit-log route — EPIC-16.T-006.
 *
 * EPIC-16.T-006 moves the audit log under the Compliance module
 * (`/compliance/audit`) with the enhanced viewer (full filters, CSV export,
 * expanded before/after diff) and a compliance+super role guard. This stub keeps
 * the old `/audit` URL working by forwarding to the canonical location.
 */
export default function LegacyAuditPage() {
  redirect("/compliance/audit");
}
