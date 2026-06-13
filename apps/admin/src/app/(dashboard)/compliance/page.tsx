import { redirect } from "next/navigation";

/**
 * Compliance landing — EPIC-16.T-006.
 *
 * The Compliance module's first tab is the enhanced audit log (Admin Portal
 * spec §4.5.1 — audit log is the entry point, ahead of consent records and data
 * requests). The sidebar links the module root at `/compliance`, so this page
 * forwards to `/compliance/audit`, where the compliance+super role guard lives.
 */
export default function CompliancePage() {
  redirect("/compliance/audit");
}
