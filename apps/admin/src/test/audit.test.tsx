import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { AuditLogClient } from "@/app/(dashboard)/compliance/audit/audit_client";
import type { AuditPage as AuditPageData, AuditEntry } from "@/lib/api/audit";

const fetchAuditLog = vi.fn<(...args: unknown[]) => Promise<AuditPageData>>();

vi.mock("@/lib/api/audit", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/audit")>("@/lib/api/audit");
  return {
    ...actual,
    fetchAuditLog: (...args: unknown[]) => fetchAuditLog(...args),
  };
});

function makeEntry(overrides: Partial<AuditEntry> = {}): AuditEntry {
  return {
    id: 1,
    action: "admin_user.disable",
    actor: "Karim Uddin",
    admin_user: 7,
    entity_type: "accounts.user",
    entity_id: "42",
    before_json: { disabled: false },
    after_json: { disabled: true },
    ip: "203.0.113.9",
    reason: "Offboarding",
    created_at: "2026-06-05T10:00:00Z",
    ...overrides,
  };
}

function makePage(
  results: AuditEntry[],
  pagination: Partial<AuditPageData["pagination"]> = {},
): AuditPageData {
  return {
    results,
    pagination: { next: null, previous: null, count: results.length, ...pagination },
  };
}

function renderPage() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<AuditLogClient />, { wrapper });
}

describe("AuditLogClient", () => {
  beforeEach(() => {
    fetchAuditLog.mockReset();
  });

  it("renders audit entries in the table", async () => {
    fetchAuditLog.mockResolvedValue(makePage([makeEntry()]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("admin_user.disable")).toBeTruthy();
    });
    expect(screen.getByText("Karim Uddin")).toBeTruthy();
    expect(screen.getByText("accounts.user #42")).toBeTruthy();
  });

  it("expands the before/after diff", async () => {
    fetchAuditLog.mockResolvedValue(makePage([makeEntry()]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("admin_user.disable")).toBeTruthy();
    });

    expect(screen.queryByText("Before")).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Show diff" }));
    expect(screen.getByText("Before")).toBeTruthy();
    expect(screen.getByText("After")).toBeTruthy();
    expect(screen.getByText(/Offboarding/)).toBeTruthy();
  });

  it("re-queries with the new filter when a filter changes", async () => {
    fetchAuditLog.mockResolvedValue(makePage([makeEntry()]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("admin_user.disable")).toBeTruthy();
    });

    fireEvent.change(screen.getByLabelText("Filter by action"), {
      target: { value: "feature_flag.toggle" },
    });

    await waitFor(() => {
      expect(fetchAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({ action: "feature_flag.toggle" }),
      );
    });
  });

  it("paginates to the next page using the cursor", async () => {
    fetchAuditLog.mockResolvedValueOnce(
      makePage([makeEntry({ id: 1, action: "page.one" })], {
        next: "http://api/admin/api/audit-log?cursor=NEXTCURSOR",
      }),
    );
    fetchAuditLog.mockResolvedValueOnce(
      makePage([makeEntry({ id: 2, action: "page.two" })]),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("page.one")).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    await waitFor(() => {
      expect(fetchAuditLog).toHaveBeenLastCalledWith(
        expect.objectContaining({ cursor: "NEXTCURSOR" }),
      );
    });
  });

  it("shows the empty state when there are no entries", async () => {
    fetchAuditLog.mockResolvedValue(makePage([]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("No audit entries")).toBeTruthy();
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchAuditLog.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Could not load the audit log")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("renders a CSV export link that targets the format=csv endpoint", async () => {
    fetchAuditLog.mockResolvedValue(makePage([makeEntry()]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("admin_user.disable")).toBeTruthy();
    });

    const exportLink = screen.getByRole("link", {
      name: "Export filtered audit log as CSV",
    });
    const href = exportLink.getAttribute("href") ?? "";
    expect(href).toContain("/admin/api/audit-log");
    expect(href).toContain("format=csv");
    expect(exportLink.getAttribute("download")).toBe("audit-log.csv");
  });

  it("threads the active filters into the CSV export link", async () => {
    fetchAuditLog.mockResolvedValue(makePage([makeEntry()]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("admin_user.disable")).toBeTruthy();
    });

    fireEvent.change(screen.getByLabelText("Filter by action"), {
      target: { value: "feature_flag.toggle" },
    });

    await waitFor(() => {
      const href =
        screen
          .getByRole("link", { name: "Export filtered audit log as CSV" })
          .getAttribute("href") ?? "";
      expect(href).toContain("action=feature_flag.toggle");
      expect(href).toContain("format=csv");
    });
  });
});
