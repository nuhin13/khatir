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
import { UserDetail } from "@/components/admin/user_detail";
import type {
  AdminUserDetail,
  AdminUserRow,
} from "@/lib/api/users";
import type { PricingTier } from "@/lib/api/pricing";

const fetchUserDetail =
  vi.fn<(...a: unknown[]) => Promise<AdminUserDetail>>();
const suspendUser = vi.fn<(...a: unknown[]) => Promise<AdminUserRow>>();
const reactivateUser = vi.fn<(...a: unknown[]) => Promise<AdminUserRow>>();
const upgradeSubscription = vi.fn<(...a: unknown[]) => Promise<unknown>>();
const fetchPricingTiers = vi.fn<() => Promise<PricingTier[]>>();

vi.mock("@/lib/api/users", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/users")>("@/lib/api/users");
  return {
    ...actual,
    fetchUserDetail: (...a: unknown[]) => fetchUserDetail(...a),
    suspendUser: (...a: unknown[]) => suspendUser(...a),
    reactivateUser: (...a: unknown[]) => reactivateUser(...a),
    upgradeSubscription: (...a: unknown[]) => upgradeSubscription(...a),
  };
});

vi.mock("@/lib/api/pricing", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/pricing")>(
      "@/lib/api/pricing",
    );
  return {
    ...actual,
    fetchPricingTiers: () => fetchPricingTiers(),
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

function makeDetail(
  overrides: Partial<AdminUserDetail> = {},
): AdminUserDetail {
  return {
    user: makeRow(),
    subscription: {
      id: 7,
      tier: 3,
      tier_key: "growth",
      tier_label: "Growth",
      billing_cycle: "monthly",
      status: "active",
      start_at: "2026-02-01T00:00:00Z",
      next_billing_at: "2026-07-01T00:00:00Z",
    },
    usage: { buildings: 3, tenant_profiles: 12, subscriptions: 1 },
    audit_trail: [
      {
        id: 100,
        action: "suspend_user",
        admin_user: 1,
        reason: "Fraud review",
        before_json: null,
        after_json: null,
        created_at: "2026-05-01T09:00:00Z",
      },
    ],
    ...overrides,
  };
}

function renderDetail(canWrite = true, id = "42") {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<UserDetail id={id} canWrite={canWrite} />, { wrapper });
}

describe("UserDetail", () => {
  beforeEach(() => {
    fetchUserDetail.mockReset();
    suspendUser.mockReset();
    reactivateUser.mockReset();
    upgradeSubscription.mockReset();
    fetchPricingTiers.mockReset();
    fetchPricingTiers.mockResolvedValue([]);
  });

  it("renders the profile, subscription, usage, and audit trail", async () => {
    fetchUserDetail.mockResolvedValue(makeDetail());
    renderDetail();

    await waitFor(() => {
      expect(
        screen.getByRole("heading", { name: "Karim Uddin" }),
      ).toBeTruthy();
    });
    // Profile + masked phone (never raw).
    expect(screen.getAllByText("+8801•••••89").length).toBeGreaterThan(0);
    expect(screen.queryByText("+8801712345689")).toBeNull();
    // Subscription tier label.
    expect(screen.getByText("Growth")).toBeTruthy();
    // Usage counters.
    expect(screen.getByText("Buildings")).toBeTruthy();
    expect(screen.getByText("12")).toBeTruthy();
    // Audit trail action row.
    const audit = screen.getByRole("table", { name: "Audit trail" });
    expect(within(audit).getByText("suspend_user")).toBeTruthy();
    expect(within(audit).getByText("Fraud review")).toBeTruthy();
  });

  it("shows the active status badge for an active user", async () => {
    fetchUserDetail.mockResolvedValue(makeDetail());
    renderDetail();
    await waitFor(() => {
      expect(screen.getByText("Active")).toBeTruthy();
    });
  });

  it("opens the suspend dialog with a required reason", async () => {
    fetchUserDetail.mockResolvedValue(makeDetail());
    renderDetail();

    fireEvent.click(await screen.findByRole("button", { name: "Suspend" }));

    const dialog = await screen.findByRole("dialog", {
      name: "Suspend account",
    });
    // Confirm is disabled until a reason is entered.
    const confirm = within(dialog).getByRole("button", { name: "Suspend" });
    expect(confirm.hasAttribute("disabled")).toBe(true);

    fireEvent.change(within(dialog).getByLabelText("Reason"), {
      target: { value: "Confirmed fraud" },
    });
    expect(
      within(dialog).getByRole("button", { name: "Suspend" }).hasAttribute(
        "disabled",
      ),
    ).toBe(false);
  });

  it("calls suspendUser and refetches on confirm", async () => {
    fetchUserDetail
      .mockResolvedValueOnce(makeDetail())
      .mockResolvedValueOnce(makeDetail({ user: makeRow({ is_active: false }) }));
    suspendUser.mockResolvedValue(makeRow({ is_active: false }));
    renderDetail();

    fireEvent.click(await screen.findByRole("button", { name: "Suspend" }));
    const dialog = await screen.findByRole("dialog", {
      name: "Suspend account",
    });
    fireEvent.change(within(dialog).getByLabelText("Reason"), {
      target: { value: "Confirmed fraud" },
    });
    fireEvent.click(within(dialog).getByRole("button", { name: "Suspend" }));

    await waitFor(() => {
      expect(suspendUser).toHaveBeenCalledWith("42", "Confirmed fraud");
    });
    // After the action the detail refetches and the badge flips to Suspended.
    await waitFor(() => {
      expect(screen.getByText("Suspended")).toBeTruthy();
    });
  });

  it("shows a Reactivate action for a suspended user", async () => {
    fetchUserDetail.mockResolvedValue(
      makeDetail({ user: makeRow({ is_active: false }) }),
    );
    renderDetail();

    fireEvent.click(await screen.findByRole("button", { name: "Reactivate" }));
    expect(
      await screen.findByRole("dialog", { name: "Reactivate account" }),
    ).toBeTruthy();
  });

  it("opens the upgrade dialog with tier + required reason", async () => {
    fetchUserDetail.mockResolvedValue(makeDetail());
    fetchPricingTiers.mockResolvedValue([
      {
        id: 5,
        key: "scale",
        label: "Scale",
        label_bn: "স্কেল",
        tenant_min: 11,
        tenant_max: null,
        monthly_price: "2000",
        annual_price: null,
        includes_verification: true,
        included_credits: 10,
        active: true,
        sort_order: 3,
        created_at: "2026-01-01T00:00:00Z",
        updated_at: "2026-01-01T00:00:00Z",
      },
    ]);
    renderDetail();

    fireEvent.click(
      await screen.findByRole("button", { name: "Upgrade subscription" }),
    );
    const dialog = await screen.findByRole("dialog", {
      name: "Upgrade subscription",
    });
    // Tier option from the pricing list is offered.
    await waitFor(() => {
      expect(within(dialog).getByText("Scale")).toBeTruthy();
    });
    // Apply disabled until tier + reason supplied.
    const apply = within(dialog).getByRole("button", { name: "Apply upgrade" });
    expect(apply.hasAttribute("disabled")).toBe(true);

    fireEvent.change(within(dialog).getByLabelText("Tier"), {
      target: { value: "5" },
    });
    fireEvent.change(within(dialog).getByLabelText("Reason"), {
      target: { value: "Goodwill upgrade" },
    });
    expect(
      within(dialog)
        .getByRole("button", { name: "Apply upgrade" })
        .hasAttribute("disabled"),
    ).toBe(false);

    fireEvent.click(
      within(dialog).getByRole("button", { name: "Apply upgrade" }),
    );
    await waitFor(() => {
      expect(upgradeSubscription).toHaveBeenCalledWith("42", {
        tierId: 5,
        billingCycle: "monthly",
        reason: "Goodwill upgrade",
      });
    });
  });

  it("hides action buttons for read-only (support) viewers", async () => {
    fetchUserDetail.mockResolvedValue(makeDetail());
    renderDetail(false);

    await waitFor(() => {
      expect(
        screen.getByRole("heading", { name: "Karim Uddin" }),
      ).toBeTruthy();
    });
    expect(screen.queryByRole("button", { name: "Suspend" })).toBeNull();
    expect(
      screen.queryByRole("button", { name: "Upgrade subscription" }),
    ).toBeNull();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchUserDetail.mockRejectedValue(new Error("network"));
    renderDetail();

    await waitFor(() => {
      expect(screen.getByText("Could not load user")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
