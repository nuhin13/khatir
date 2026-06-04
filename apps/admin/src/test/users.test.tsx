import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { UsersBrowser } from "@/components/admin/users_browser";
import type { AdminUserPage, AdminUserRow } from "@/lib/api/users";

const fetchUsers = vi.fn<(...args: unknown[]) => Promise<AdminUserPage>>();

vi.mock("@/lib/api/users", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/users")>("@/lib/api/users");
  return {
    ...actual,
    fetchUsers: (...args: unknown[]) => fetchUsers(...args),
  };
});

function makeRow(overrides: Partial<AdminUserRow> = {}): AdminUserRow {
  return {
    id: 42,
    name: "Karim Uddin",
    phone: "+8801712345689",
    masked_phone: "+8801•••••89",
    role: "landlord",
    language: "bn",
    is_active: true,
    last_login_at: "2026-06-04T10:00:00Z",
    created_at: "2026-01-01T10:00:00Z",
    ...overrides,
  };
}

function makePage(
  results: AdminUserRow[],
  pagination: Partial<AdminUserPage["pagination"]> = {},
): AdminUserPage {
  return {
    results,
    pagination: {
      next: null,
      previous: null,
      count: results.length,
      ...pagination,
    },
  };
}

function renderBrowser() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<UsersBrowser />, { wrapper });
}

describe("UsersBrowser", () => {
  beforeEach(() => {
    fetchUsers.mockReset();
  });

  it("renders the user rows in the table", async () => {
    fetchUsers.mockResolvedValue(makePage([makeRow()]));
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("Karim Uddin")).toBeTruthy();
    });
    expect(screen.getByText("landlord")).toBeTruthy();
    expect(screen.getByText("Active")).toBeTruthy();
  });

  it("shows the masked phone and never the raw phone number", async () => {
    fetchUsers.mockResolvedValue(makePage([makeRow()]));
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("+8801•••••89")).toBeTruthy();
    });
    expect(screen.queryByText("+8801712345689")).toBeNull();
  });

  it("links each row to the user-detail page", async () => {
    fetchUsers.mockResolvedValue(makePage([makeRow({ id: 99 })]));
    renderBrowser();

    const link = await screen.findByRole("link", { name: "Karim Uddin" });
    expect(link.getAttribute("href")).toBe("/users/99");
  });

  it("re-queries with the search term when the form is submitted", async () => {
    fetchUsers.mockResolvedValue(makePage([makeRow()]));
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("Karim Uddin")).toBeTruthy();
    });

    fireEvent.change(
      screen.getByLabelText("Search by phone, name, or ID"),
      { target: { value: "01712" } },
    );
    fireEvent.click(screen.getByRole("button", { name: "Search" }));

    await waitFor(() => {
      expect(fetchUsers).toHaveBeenCalledWith(
        expect.objectContaining({ q: "01712", page: 1 }),
      );
    });
  });

  it("suspended users show a Suspended status chip", async () => {
    fetchUsers.mockResolvedValue(
      makePage([makeRow({ is_active: false })]),
    );
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("Suspended")).toBeTruthy();
    });
  });

  it("paginates to the next page", async () => {
    fetchUsers.mockResolvedValueOnce(
      makePage([makeRow({ id: 1, name: "Page One User" })], {
        next: "http://api/admin/api/users?page=2",
      }),
    );
    fetchUsers.mockResolvedValueOnce(
      makePage([makeRow({ id: 2, name: "Page Two User" })], {
        previous: "http://api/admin/api/users",
      }),
    );
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("Page One User")).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    await waitFor(() => {
      expect(fetchUsers).toHaveBeenLastCalledWith(
        expect.objectContaining({ page: 2 }),
      );
    });
  });

  it("shows the empty state when there are no matches", async () => {
    fetchUsers.mockResolvedValue(makePage([]));
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("No users found")).toBeTruthy();
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchUsers.mockRejectedValue(new Error("network"));
    renderBrowser();

    await waitFor(() => {
      expect(screen.getByText("Could not load users")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
