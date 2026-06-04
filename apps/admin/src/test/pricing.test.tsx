import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  within,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { PricingEditor } from "@/components/admin/pricing_editor";
import type {
  PricingTier,
  TierImpactResponse,
} from "@/lib/api/pricing";

const fetchPricingTiers = vi.fn<() => Promise<PricingTier[]>>();
const previewTier = vi.fn<() => Promise<TierImpactResponse>>();
const editTier = vi.fn<() => Promise<PricingTier>>();

vi.mock("@/lib/api/pricing", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/pricing")>(
      "@/lib/api/pricing",
    );
  return {
    ...actual,
    fetchPricingTiers: () => fetchPricingTiers(),
    previewTier: () => previewTier(),
    editTier: () => editTier(),
  };
});

function makeTier(overrides: Partial<PricingTier> = {}): PricingTier {
  return {
    id: 1,
    key: "unlimited_annual",
    label: "Unlimited Annual",
    label_bn: "অনিয়মিত বার্ষিক",
    tenant_min: 1,
    tenant_max: null,
    monthly_price: "999.00",
    annual_price: "11988.00",
    includes_verification: true,
    included_credits: 60,
    active: true,
    sort_order: 6,
    created_at: "2026-06-01T00:00:00Z",
    updated_at: "2026-06-01T00:00:00Z",
    ...overrides,
  };
}

function renderPage() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<PricingEditor />, { wrapper });
}

describe("PricingEditor", () => {
  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    fetchPricingTiers.mockReset();
    previewTier.mockReset();
    editTier.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders the tier rows from the API", async () => {
    fetchPricingTiers.mockResolvedValue([
      makeTier(),
      makeTier({ id: 2, key: "free", label: "Free", monthly_price: "0.00" }),
    ]);
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Unlimited Annual")).toBeTruthy();
    });
    expect(screen.getByText("Free")).toBeTruthy();
    // free tier price renders as FREE
    expect(screen.getByText("FREE")).toBeTruthy();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchPricingTiers.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Could not load pricing tiers")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("opens the editor, calls preview, then confirm calls edit", async () => {
    fetchPricingTiers.mockResolvedValue([makeTier()]);
    previewTier.mockResolvedValue({
      subscribers_affected: 1420,
      monthly_revenue_delta: "-71000.00",
    });
    editTier.mockResolvedValue(makeTier({ monthly_price: "949.00" }));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Unlimited Annual")).toBeTruthy();
    });

    // open the inline editor
    fireEvent.click(screen.getByRole("button", { name: "Edit Unlimited Annual" }));
    const dialog = screen.getByRole("dialog", {
      name: "Edit tier Unlimited Annual",
    });
    expect(dialog).toBeTruthy();

    // preview is disabled until a reason is given
    const previewBtn = within(dialog).getByRole("button", {
      name: /Preview impact/,
    }) as HTMLButtonElement;
    expect(previewBtn.disabled).toBe(true);

    fireEvent.change(
      within(dialog).getByLabelText("Reason for change (required)"),
      { target: { value: "Q3 pricing review" } },
    );
    expect(previewBtn.disabled).toBe(false);

    fireEvent.click(previewBtn);
    await waitFor(() => {
      expect(previewTier).toHaveBeenCalledTimes(1);
    });

    // the impact-preview confirm modal opens with the subscriber count
    await waitFor(() => {
      expect(screen.getByText("1,420")).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Apply change" }));
    await waitFor(() => {
      expect(editTier).toHaveBeenCalledTimes(1);
    });
  });

  it("does not call preview while the reason is blank", async () => {
    fetchPricingTiers.mockResolvedValue([makeTier()]);
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Unlimited Annual")).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Edit Unlimited Annual" }));

    const dialog = screen.getByRole("dialog", {
      name: "Edit tier Unlimited Annual",
    });
    fireEvent.click(
      within(dialog).getByRole("button", { name: /Preview impact/ }),
    );
    expect(previewTier).not.toHaveBeenCalled();
  });
});
