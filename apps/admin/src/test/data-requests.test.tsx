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
import { DataRequestsClient } from "@/app/(dashboard)/compliance/requests/requests_client";
import type {
  DataRequest,
  DataRequestPage,
} from "@/lib/api/data-requests";

const fetchDataRequests =
  vi.fn<(...args: unknown[]) => Promise<DataRequestPage>>();
const processDataRequest =
  vi.fn<(...args: unknown[]) => Promise<DataRequest>>();

vi.mock("@/lib/api/data-requests", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/data-requests")>(
      "@/lib/api/data-requests",
    );
  return {
    ...actual,
    fetchDataRequests: (...args: unknown[]) => fetchDataRequests(...args),
    processDataRequest: (...args: unknown[]) => processDataRequest(...args),
  };
});

function makeRequest(overrides: Partial<DataRequest> = {}): DataRequest {
  return {
    id: 1,
    user: 42,
    request_type: "export",
    status: "pending",
    sla_due: "2026-06-10",
    sla_state: "on_track",
    completed_at: null,
    handled_by: null,
    created_at: "2026-06-01T10:00:00Z",
    updated_at: "2026-06-01T10:00:00Z",
    ...overrides,
  };
}

function makePage(
  results: DataRequest[],
  pagination: Partial<DataRequestPage["pagination"]> = {},
): DataRequestPage {
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

function inTable(name: string, text: string) {
  const table = screen.getByRole("table", { name });
  return within(table).getByText(text);
}

function renderPage() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<DataRequestsClient />, { wrapper });
}

describe("DataRequestsClient", () => {
  beforeEach(() => {
    fetchDataRequests.mockReset();
    processDataRequest.mockReset();
  });

  it("renders pending requests with an SLA badge", async () => {
    fetchDataRequests.mockResolvedValue(
      makePage([makeRequest({ sla_state: "overdue" })]),
    );
    renderPage();

    await waitFor(() => {
      expect(inTable("Pending data requests", "Export")).toBeTruthy();
    });
    expect(screen.getByText("#42")).toBeTruthy();
    expect(screen.getByText("Overdue")).toBeTruthy();
  });

  it("only requests pending rows on the pending tab", async () => {
    fetchDataRequests.mockResolvedValue(makePage([makeRequest()]));
    renderPage();

    await waitFor(() => {
      expect(fetchDataRequests).toHaveBeenCalledWith(
        expect.objectContaining({ status: "pending" }),
      );
    });
  });

  it("shows the empty state when there are no pending requests", async () => {
    fetchDataRequests.mockResolvedValue(makePage([]));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("No pending data requests")).toBeTruthy();
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchDataRequests.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Could not load data requests")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("approves a request via the confirm dialog", async () => {
    fetchDataRequests.mockResolvedValue(makePage([makeRequest()]));
    processDataRequest.mockResolvedValue(
      makeRequest({ status: "processing" }),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Approve" })).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Approve" }));

    const dialog = await screen.findByRole("dialog", {
      name: "Approve data request",
    });
    fireEvent.click(within(dialog).getByRole("button", { name: "Approve" }));

    await waitFor(() => {
      expect(processDataRequest).toHaveBeenCalledWith(
        1,
        expect.objectContaining({ approve: true }),
      );
    });
  });

  it("requires a reason before a rejection can be submitted", async () => {
    fetchDataRequests.mockResolvedValue(makePage([makeRequest()]));
    processDataRequest.mockResolvedValue(makeRequest({ status: "rejected" }));
    renderPage();

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Reject" })).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Reject" }));

    const dialog = await screen.findByRole("dialog", {
      name: "Reject data request",
    });
    const submit = within(dialog).getByRole("button", { name: "Reject" });
    expect(submit.hasAttribute("disabled")).toBe(true);

    fireEvent.change(within(dialog).getByLabelText("Reason"), {
      target: { value: "Could not verify identity" },
    });
    expect(submit.hasAttribute("disabled")).toBe(false);

    fireEvent.click(submit);
    await waitFor(() => {
      expect(processDataRequest).toHaveBeenCalledWith(
        1,
        expect.objectContaining({
          approve: false,
          reason: "Could not verify identity",
        }),
      );
    });
  });

  it("shows resolved rows on the completed tab", async () => {
    fetchDataRequests.mockResolvedValueOnce(makePage([makeRequest()]));
    fetchDataRequests.mockResolvedValueOnce(
      makePage([
        makeRequest({
          id: 2,
          status: "completed",
          completed_at: "2026-06-04T09:00:00Z",
          handled_by: 7,
        }),
      ]),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByRole("tab", { name: "Completed" })).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("tab", { name: "Completed" }));

    await waitFor(() => {
      expect(inTable("Completed data requests", "Completed")).toBeTruthy();
    });
    expect(screen.getByText("#7")).toBeTruthy();
  });
});
