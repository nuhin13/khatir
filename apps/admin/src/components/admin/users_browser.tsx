"use client";

import { useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { Card, CardTitle, CardDescription } from "@/components/ui/card";
import { UsersTable } from "@/components/admin/users_table";
import {
  usersQueryKey,
  fetchUsers,
  type UserSearchFilters,
} from "@/lib/api/users";

/**
 * Users browser — EPIC-12.T-007 (client island).
 *
 * Owns the search + page-number state and fetches `GET /admin/api/users` via
 * TanStack Query. Page-number pagination keeps the previous page visible while
 * the next loads (`keepPreviousData`). Loading / error / empty / data states
 * are all handled here; the presentational {@link UsersTable} renders rows. The
 * server component (`page.tsx`) enforces the ops+super role guard before this
 * island ever mounts.
 */
export function UsersBrowser() {
  const [filters, setFilters] = useState<UserSearchFilters>({ page: 1 });

  const { data, isPending, isError, refetch } = useQuery({
    queryKey: usersQueryKey(filters),
    queryFn: () => fetchUsers(filters),
    placeholderData: keepPreviousData,
  });

  const hasNext = Boolean(data?.pagination.next);
  const hasPrevious = Boolean(data?.pagination.previous);

  return (
    <div className="space-y-s6">
      <div>
        <h1 className="font-title text-2xl font-bold text-ink">Users</h1>
        <p className="mt-s1 text-sm text-muted">
          Find any account by phone, name, or ID. Phone numbers are masked in
          this list; open a user to see full detail.
        </p>
      </div>

      {isPending ? (
        <Card
          className="h-64 animate-pulse"
          aria-busy
          aria-label="Loading users"
        />
      ) : isError ? (
        <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
          <CardTitle>Could not load users</CardTitle>
          <CardDescription>
            The user-search request failed. Check your connection and try again.
          </CardDescription>
          <button
            type="button"
            onClick={() => void refetch()}
            className="mt-s2 rounded-button bg-ink px-s5 py-s2 font-title text-sm font-semibold text-card"
          >
            Retry
          </button>
        </Card>
      ) : (
        <UsersTable
          users={data.results}
          filters={filters}
          onSearch={(q) => setFilters({ q, page: 1 })}
          hasNext={hasNext}
          hasPrevious={hasPrevious}
          onNext={() =>
            setFilters((f) => ({ ...f, page: (f.page ?? 1) + 1 }))
          }
          onPrevious={() =>
            setFilters((f) => ({ ...f, page: Math.max(1, (f.page ?? 1) - 1) }))
          }
        />
      )}
    </div>
  );
}
