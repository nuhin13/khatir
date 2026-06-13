import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  within,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { AIUsagePanel } from "@/components/admin/ai_usage_panel";
import {
  errorRate,
  successRate,
  aiUsageQueryKey,
  type AIUsage,
  type AIUsageRange,
} from "@/lib/api/ai-usage";

const fetchAIUsage = vi.fn<(range?: AIUsageRange) => Promise<AIUsage>>();

vi.mock("@/lib/api/ai-usage", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/ai-usage")>(
      "@/lib/api/ai-usage",
    );
  return {
    ...actual,
    fetchAIUsage: (range?: AIUsageRange) => fetchAIUsage(range),
  };
});

function makeUsage(overrides: Partial<AIUsage> = {}): AIUsage {
  return {
    by_category: [
      {
        category: "ocr",
        request_count: 120,
        tokens_used: 0,
        cost_usd: "12.50",
        call_count: 100,
        success_count: 95,
      },
      {
        category: "chat",
        request_count: 80,
        tokens_used: 40000,
        cost_usd: "8.00",
        call_count: 80,
        success_count: 80,
      },
    ],
    totals: {
      request_count: 200,
      tokens_used: 40000,
      cost_usd: "20.50",
      call_count: 180,
      success_count: 175,
    },
    ...overrides,
  };
}

function renderPanel() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<AIUsagePanel />, { wrapper });
}

describe("ai-usage helpers", () => {
  it("computes error and success rate from call counts", () => {
    expect(errorRate({ call_count: 100, success_count: 95 })).toBeCloseTo(0.05);
    expect(successRate({ call_count: 100, success_count: 95 })).toBeCloseTo(
      0.95,
    );
  });
  it("returns null when there are no calls", () => {
    expect(errorRate({ call_count: 0, success_count: 0 })).toBeNull();
    expect(successRate({ call_count: 0, success_count: 0 })).toBeNull();
  });
  it("scopes the query key by the date range", () => {
    expect(aiUsageQueryKey({ from: "2026-01-01", to: "2026-01-31" })).toEqual([
      "admin",
      "ai-usage",
      "2026-01-01",
      "2026-01-31",
    ]);
    expect(aiUsageQueryKey({})).toEqual(["admin", "ai-usage", "", ""]);
  });
});

describe("AIUsagePanel", () => {
  beforeEach(() => {
    fetchAIUsage.mockReset();
  });

  it("renders the usage table with a row per category", async () => {
    fetchAIUsage.mockResolvedValue(makeUsage());
    renderPanel();

    const table = await screen.findByRole("table", {
      name: "AI usage by category",
    });
    // All four categories appear (even ones with no logged usage).
    expect(within(table).getByText("OCR / Vision")).toBeTruthy();
    expect(within(table).getByText("Chat / LLM")).toBeTruthy();
    expect(within(table).getByText("Voice / ASR")).toBeTruthy();
    expect(within(table).getByText("Lease generation")).toBeTruthy();
    // OCR cost + derived error rate (5/100) are shown.
    expect(within(table).getByText("$12.50")).toBeTruthy();
    expect(within(table).getByText("5.0%")).toBeTruthy();
  });

  it("shows the running cost total for the period", async () => {
    fetchAIUsage.mockResolvedValue(makeUsage());
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("Total cost (USD)")).toBeTruthy();
    });
    expect(screen.getByText("$20.50")).toBeTruthy();
  });

  it("lists categories with failed calls in the failover & error log", async () => {
    fetchAIUsage.mockResolvedValue(makeUsage());
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("Failover & errors")).toBeTruthy();
    });
    // OCR failed 5 of 100; chat had none → only OCR is logged.
    expect(screen.getByText("5 of 100 calls failed")).toBeTruthy();
  });

  it("shows an all-clear state when there are no failed calls", async () => {
    fetchAIUsage.mockResolvedValue(
      makeUsage({
        by_category: [
          {
            category: "chat",
            request_count: 10,
            tokens_used: 100,
            cost_usd: "1.00",
            call_count: 10,
            success_count: 10,
          },
        ],
        totals: {
          request_count: 10,
          tokens_used: 100,
          cost_usd: "1.00",
          call_count: 10,
          success_count: 10,
        },
      }),
    );
    renderPanel();

    await waitFor(() => {
      expect(
        screen.getByText("No failed calls recorded for this period."),
      ).toBeTruthy();
    });
  });

  it("re-fetches with the selected date range", async () => {
    fetchAIUsage.mockResolvedValue(makeUsage());
    renderPanel();

    await waitFor(() => {
      expect(fetchAIUsage).toHaveBeenCalledWith({});
    });

    const filter = screen.getByRole("form", { name: "Usage date filter" });
    const [fromInput, toInput] = within(filter).getAllByDisplayValue("");
    fireEvent.change(fromInput, { target: { value: "2026-01-01" } });
    fireEvent.change(toInput, { target: { value: "2026-01-31" } });

    await waitFor(() => {
      expect(fetchAIUsage).toHaveBeenCalledWith({
        from: "2026-01-01",
        to: "2026-01-31",
      });
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchAIUsage.mockRejectedValue(new Error("network"));
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("Could not load AI usage")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
