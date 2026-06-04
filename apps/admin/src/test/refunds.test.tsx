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
import { RefundQueue } from "@/components/admin/refund_queue";
import type { RefundRequest, RefundDecision } from "@/lib/api/refunds";

const fetchRefunds = vi.fn<() => Promise<RefundRequest[]>>();
const processRefund = vi.fn<(...a: unknown[]) => Promise<RefundDecision>>();

vi.mock("@/lib/api/refunds", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/refunds")>(
      "@/lib/api/refunds",
    );
  return {
    ...actual,
    fetchRefunds: () => fetchRefunds(),
    processRefund: (...a: unknown[]) => processRefund(...a),
  };
});

function makeRow(overrides: Partial<RefundRequest> = {}): RefundRequest {
  return {
    id: 11,
    subscription_id: 7,
    user_id: 42,
    tier_key: "growth",
    billing_cycle: "monthly",
    provider: "bkash",
    state: "pending",
    created_at: "2026-06-01T10:00:00Z",
    ...overrides,
  };
}

function renderQueue() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<RefundQueue />, { wrapper });
}

describe("RefundQueue", () => {
  beforeEach(() => {
    fetchRefunds.mockReset();
    processRefund.mockReset();
  });

  it("renders pending refund rows", async () => {
    fetchRefunds.mockResolvedValue([makeRow()]);
    renderQueue();

    const table = await screen.findByRole("table", { name: "Refund queue" });
    expect(within(table).getByText("#42")).toBeTruthy();
    expect(within(table).getByText("growth")).toBeTruthy();
    expect(within(table).getByText("bkash")).toBeTruthy();
    expect(
      within(table).getByRole("button", { name: "Approve" }),
    ).toBeTruthy();
    expect(within(table).getByRole("button", { name: "Deny" })).toBeTruthy();
  });

  it("shows an empty state when there are no refunds", async () => {
    fetchRefunds.mockResolvedValue([]);
    renderQueue();
    await waitFor(() => {
      expect(screen.getByText("No pending refunds")).toBeTruthy();
    });
  });

  it("approves a refund (reason optional) and refetches", async () => {
    fetchRefunds
      .mockResolvedValueOnce([makeRow()])
      .mockResolvedValueOnce([]);
    processRefund.mockResolvedValue({
      intent_id: 11,
      decision: "approved",
      state: "refunded",
      subscription_id: 7,
      subscription_status: "cancelled",
    });
    renderQueue();

    fireEvent.click(await screen.findByRole("button", { name: "Approve" }));
    const dialog = await screen.findByRole("dialog", {
      name: "Approve refund",
    });
    // Approve does not require a reason — confirm is enabled immediately.
    const confirm = within(dialog).getByRole("button", { name: "Approve" });
    expect(confirm.hasAttribute("disabled")).toBe(false);

    fireEvent.click(confirm);
    await waitFor(() => {
      expect(processRefund).toHaveBeenCalledWith(11, {
        approve: true,
        reason: "",
      });
    });
    // The processed row drops out of the refetched queue.
    await waitFor(() => {
      expect(screen.getByText("No pending refunds")).toBeTruthy();
    });
  });

  it("requires a reason to deny", async () => {
    fetchRefunds.mockResolvedValue([makeRow()]);
    processRefund.mockResolvedValue({
      intent_id: 11,
      decision: "denied",
      state: "refund_denied",
      subscription_id: 7,
      subscription_status: "active",
    });
    renderQueue();

    fireEvent.click(await screen.findByRole("button", { name: "Deny" }));
    const dialog = await screen.findByRole("dialog", { name: "Deny refund" });

    // Confirm disabled until a reason is supplied.
    expect(
      within(dialog).getByRole("button", { name: "Deny" }).hasAttribute(
        "disabled",
      ),
    ).toBe(true);

    fireEvent.change(within(dialog).getByLabelText("Reason"), {
      target: { value: "Outside refund window" },
    });
    const confirm = within(dialog).getByRole("button", { name: "Deny" });
    expect(confirm.hasAttribute("disabled")).toBe(false);

    fireEvent.click(confirm);
    await waitFor(() => {
      expect(processRefund).toHaveBeenCalledWith(11, {
        approve: false,
        reason: "Outside refund window",
      });
    });
  });

  it("shows an error state with retry when the fetch fails", async () => {
    fetchRefunds.mockRejectedValue(new Error("network"));
    renderQueue();

    await waitFor(() => {
      expect(screen.getByText("Could not load refunds")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
