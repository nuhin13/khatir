import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  render,
  screen,
  waitFor,
  fireEvent,
  within,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { ConsentRecordsClient } from "@/app/(dashboard)/compliance/consent/consent_client";
import type {
  ConsentPage as ConsentPageData,
  ConsentRecord,
} from "@/lib/api/consent";

const fetchConsentRecords =
  vi.fn<(...args: unknown[]) => Promise<ConsentPageData>>();

vi.mock("@/lib/api/consent", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/consent")>(
      "@/lib/api/consent",
    );
  return {
    ...actual,
    fetchConsentRecords: (...args: unknown[]) => fetchConsentRecords(...args),
  };
});

function makeRecord(overrides: Partial<ConsentRecord> = {}): ConsentRecord {
  return {
    id: 1,
    user: 42,
    consent_type: "pdpa_data_collection",
    granted_at: "2026-06-01T10:00:00Z",
    revoked_at: null,
    expires_at: "2027-06-01T10:00:00Z",
    created_at: "2026-06-01T10:00:00Z",
    updated_at: "2026-06-01T10:00:00Z",
    ...overrides,
  };
}

function makePage(
  results: ConsentRecord[],
  pagination: Partial<ConsentPageData["pagination"]> = {},
): ConsentPageData {
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

/** Find text inside the rendered consent table (the select also lists types). */
function inTable(text: string) {
  const table = screen.getByRole("table", { name: "Consent records" });
  return within(table).getByText(text);
}

function renderPage() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<ConsentRecordsClient />, { wrapper });
}

describe("ConsentRecordsClient", () => {
  beforeEach(() => {
    fetchConsentRecords.mockReset();
  });

  it("renders consent records in the table", async () => {
    fetchConsentRecords.mockResolvedValue(makePage([makeRecord()]));
    renderPage();

    await waitFor(() => {
      expect(inTable("PDPA data collection")).toBeTruthy();
    });
    expect(screen.getByText("#42")).toBeTruthy();
  });

  it("re-queries with the new filter when the consent type changes", async () => {
    fetchConsentRecords.mockResolvedValue(makePage([makeRecord()]));
    renderPage();

    await waitFor(() => {
      expect(inTable("PDPA data collection")).toBeTruthy();
    });

    fireEvent.change(screen.getByLabelText("Filter by consent type"), {
      target: { value: "marketing" },
    });

    await waitFor(() => {
      expect(fetchConsentRecords).toHaveBeenCalledWith(
        expect.objectContaining({ consent_type: "marketing" }),
      );
    });
  });

  it("re-queries with the new filter when the user changes", async () => {
    fetchConsentRecords.mockResolvedValue(makePage([makeRecord()]));
    renderPage();

    await waitFor(() => {
      expect(inTable("PDPA data collection")).toBeTruthy();
    });

    fireEvent.change(screen.getByLabelText("Filter by user"), {
      target: { value: "99" },
    });

    await waitFor(() => {
      expect(fetchConsentRecords).toHaveBeenCalledWith(
        expect.objectContaining({ user: "99" }),
      );
    });
  });

  it("paginates to the next page using the page number", async () => {
    fetchConsentRecords.mockResolvedValueOnce(
      makePage([makeRecord({ id: 1, user: 1 })], {
        next: "http://api/admin/api/consent-records?page=2",
      }),
    );
    fetchConsentRecords.mockResolvedValueOnce(
      makePage([makeRecord({ id: 2, user: 2 })]),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("#1")).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    await waitFor(() => {
      expect(fetchConsentRecords).toHaveBeenLastCalledWith(
        expect.objectContaining({ page: "2" }),
      );
    });
  });

  it("shows the empty state when there are no records", async () => {
    fetchConsentRecords.mockResolvedValue(makePage([]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("No consent records")).toBeTruthy();
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchConsentRecords.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Could not load consent records")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("renders a dash for a null revoked_at", async () => {
    fetchConsentRecords.mockResolvedValue(
      makePage([makeRecord({ revoked_at: null })]),
    );
    renderPage();

    await waitFor(() => {
      expect(inTable("PDPA data collection")).toBeTruthy();
    });
    expect(screen.getAllByText("—").length).toBeGreaterThan(0);
  });
});
