"use client";

import Link from "next/link";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from "@/components/ui/table";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";
import type { AdminUserRow, UserSearchFilters } from "@/lib/api/users";

/**
 * User-search table — EPIC-12.T-007.
 *
 * Presentational: renders the search form, the paginated result table, and the
 * pager. Columns mirror Admin Portal spec §4.2 — name, phone (always the
 * server-masked form, never the raw number), role, tier, status. Each row links
 * to the user-detail page (T-008). The `Tier` column shows `—`: the compact
 * search projection (`AdminUserListSerializer`, T-003) does not carry the
 * subscription tier — that is loaded on the detail page — so the list cannot
 * fabricate it. All styling comes from Notun Din token classes (no hardcoded
 * hex/px).
 */

const COLUMNS = ["Name", "Phone", "Role", "Tier", "Status"] as const;

export interface UsersTableProps {
  users: AdminUserRow[];
  filters: UserSearchFilters;
  /** Replace the search term (resets to page 1). */
  onSearch: (q: string) => void;
  onNext?: () => void;
  onPrevious?: () => void;
  hasNext: boolean;
  hasPrevious: boolean;
}

export function UsersTable({
  users,
  filters,
  onSearch,
  onNext,
  onPrevious,
  hasNext,
  hasPrevious,
}: UsersTableProps) {
  return (
    <div className="space-y-s4">
      <UserSearchForm value={filters.q ?? ""} onSearch={onSearch} />

      {users.length === 0 ? (
        <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
          <CardTitle>No users found</CardTitle>
          <CardDescription>
            No accounts match this search. Try a phone number, name, or account
            ID.
          </CardDescription>
        </Card>
      ) : (
        <Table aria-label="Users">
          <TableHead>
            <TableRow>
              {COLUMNS.map((c) => (
                <TableHeaderCell key={c}>{c}</TableHeaderCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <UserRow key={String(user.id)} user={user} />
            ))}
          </TableBody>
        </Table>
      )}

      <div className="flex items-center justify-end gap-s3">
        <button
          type="button"
          onClick={onPrevious}
          disabled={!hasPrevious}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Previous
        </button>
        <button
          type="button"
          onClick={onNext}
          disabled={!hasNext}
          className="rounded-button border border-line px-s4 py-s2 font-title text-sm font-semibold text-ink disabled:opacity-40"
        >
          Next
        </button>
      </div>
    </div>
  );
}

function UserSearchForm({
  value,
  onSearch,
}: {
  value: string;
  onSearch: (q: string) => void;
}) {
  return (
    <form
      role="search"
      onSubmit={(e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        onSearch(String(data.get("q") ?? "").trim());
      }}
      className="flex flex-wrap items-end gap-s3"
    >
      <label className="flex flex-1 flex-col gap-s1 text-xs font-semibold text-mutedDk">
        Search users
        <input
          type="search"
          name="q"
          aria-label="Search by phone, name, or ID"
          placeholder="Phone, name, or account ID"
          defaultValue={value}
          className="rounded-sm border border-line bg-card px-s3 py-s2 text-sm text-ink placeholder:text-muted"
        />
      </label>
      <button
        type="submit"
        className="rounded-button bg-ink px-s5 py-s2 font-title text-sm font-semibold text-card"
      >
        Search
      </button>
    </form>
  );
}

function UserRow({ user }: { user: AdminUserRow }) {
  return (
    <TableRow>
      <TableCell>
        <Link
          href={`/users/${user.id}`}
          className="font-title font-semibold text-ink underline-offset-2 hover:underline"
        >
          {user.name || "(no name)"}
        </Link>
      </TableCell>
      <TableCell className="font-mono text-xs">{user.masked_phone}</TableCell>
      <TableCell className="capitalize">{user.role}</TableCell>
      <TableCell className="text-muted">—</TableCell>
      <TableCell>
        <Chip tone={user.is_active ? "sage" : "danger"}>
          {user.is_active ? "Active" : "Suspended"}
        </Chip>
      </TableCell>
    </TableRow>
  );
}
