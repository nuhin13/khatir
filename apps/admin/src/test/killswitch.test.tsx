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
import { KillSwitchPanel } from "@/components/admin/killswitch_panel";
import type { KillSwitch, KillSwitchToggleInput } from "@/lib/api/killswitch";

const fetchKillSwitches = vi.fn<() => Promise<KillSwitch[]>>();
const toggleKillSwitch =
  vi.fn<(input: KillSwitchToggleInput) => Promise<KillSwitch>>();

vi.mock("@/lib/api/killswitch", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/killswitch")>(
      "@/lib/api/killswitch",
    );
  return {
    ...actual,
    fetchKillSwitches: () => fetchKillSwitches(),
    toggleKillSwitch: (input: KillSwitchToggleInput) => toggleKillSwitch(input),
  };
});

function makeSwitch(overrides: Partial<KillSwitch> = {}): KillSwitch {
  return {
    id: 1,
    key: "warnings_feature",
    description: "All warning creation. Existing warnings remain readable.",
    scope: "global",
    enabled: true,
    value_json: null,
    updated_by: null,
    created_at: "2026-06-01T00:00:00Z",
    updated_at: "2026-06-01T00:00:00Z",
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
  return render(<KillSwitchPanel />, { wrapper });
}

describe("KillSwitchPanel", () => {
  beforeEach(() => {
    fetchKillSwitches.mockReset();
    toggleKillSwitch.mockReset();
  });

  it("renders the 5 named switches with their state", async () => {
    fetchKillSwitches.mockResolvedValue([
      makeSwitch(),
      makeSwitch({ id: 2, key: "reviews_feature", enabled: true }),
      makeSwitch({ id: 5, key: "master_kill_switch", enabled: true }),
    ]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });
    expect(screen.getByText("reviews_feature")).toBeTruthy();
    expect(screen.getByText("master_kill_switch")).toBeTruthy();
    // master switch is escalated with a badge
    expect(screen.getByText("★ MASTER")).toBeTruthy();
  });

  it("shows the red warning banner when any switch is OFF", async () => {
    fetchKillSwitches.mockResolvedValue([
      makeSwitch({ enabled: false }),
      makeSwitch({ id: 2, key: "reviews_feature", enabled: true }),
    ]);
    renderPanel();

    await waitFor(() => {
      expect(
        screen.getByText("One or more features are currently DISABLED"),
      ).toBeTruthy();
    });
  });

  it("does NOT show the warning banner when every switch is enabled", async () => {
    fetchKillSwitches.mockResolvedValue([
      makeSwitch({ enabled: true }),
      makeSwitch({ id: 2, key: "reviews_feature", enabled: true }),
    ]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });
    expect(
      screen.queryByText("One or more features are currently DISABLED"),
    ).toBeNull();
  });

  it("opens the MFA dialog on Disable and does not call the endpoint until confirmed", async () => {
    fetchKillSwitches.mockResolvedValue([makeSwitch({ enabled: true })]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });

    fireEvent.click(screen.getByRole("button", { name: "Disable" }));

    const dialog = screen.getByRole("dialog", {
      name: "Disable kill-switch warnings_feature",
    });
    expect(dialog).toBeTruthy();
    expect(toggleKillSwitch).not.toHaveBeenCalled();
    // MFA + reason fields are present (intentional friction)
    expect(within(dialog).getByLabelText(/Reason/)).toBeTruthy();
    expect(within(dialog).getByLabelText(/MFA/)).toBeTruthy();
  });

  it("blocks Confirm until a >=20-char reason AND a 6-digit MFA code are entered", async () => {
    fetchKillSwitches.mockResolvedValue([makeSwitch({ enabled: true })]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Disable" }));

    const dialog = screen.getByRole("dialog", {
      name: "Disable kill-switch warnings_feature",
    });
    const confirm = within(dialog).getByRole("button", {
      name: "Confirm with MFA →",
    });
    expect(confirm.hasAttribute("disabled")).toBe(true);

    // short reason — still blocked
    fireEvent.change(within(dialog).getByLabelText(/Reason/), {
      target: { value: "too short" },
    });
    fireEvent.change(within(dialog).getByLabelText(/MFA/), {
      target: { value: "123456" },
    });
    expect(confirm.hasAttribute("disabled")).toBe(true);

    // valid reason + valid MFA — enabled
    fireEvent.change(within(dialog).getByLabelText(/Reason/), {
      target: { value: "Legal review pending — disable per counsel memo" },
    });
    expect(confirm.hasAttribute("disabled")).toBe(false);
  });

  it("confirm fires the toggle endpoint with the MFA code, reason, and lawyer ref", async () => {
    fetchKillSwitches.mockResolvedValue([makeSwitch({ enabled: true })]);
    toggleKillSwitch.mockResolvedValue(makeSwitch({ enabled: false }));
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Disable" }));

    const dialog = screen.getByRole("dialog", {
      name: "Disable kill-switch warnings_feature",
    });
    fireEvent.change(within(dialog).getByLabelText(/Reason/), {
      target: { value: "Legal review pending — disable per counsel memo" },
    });
    fireEvent.change(within(dialog).getByLabelText(/Lawyer reference/), {
      target: { value: "Barrister Karim · Memo 2026-05-22" },
    });
    fireEvent.change(within(dialog).getByLabelText(/MFA/), {
      target: { value: "654321" },
    });

    fireEvent.click(
      within(dialog).getByRole("button", { name: "Confirm with MFA →" }),
    );

    await waitFor(() => {
      expect(toggleKillSwitch).toHaveBeenCalledTimes(1);
    });
    expect(toggleKillSwitch).toHaveBeenCalledWith({
      key: "warnings_feature",
      mfaCode: "654321",
      reason: "Legal review pending — disable per counsel memo",
      lawyerReference: "Barrister Karim · Memo 2026-05-22",
    });
  });

  it("cancelling the dialog never calls the toggle endpoint", async () => {
    fetchKillSwitches.mockResolvedValue([makeSwitch({ enabled: true })]);
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("warnings_feature")).toBeTruthy();
    });
    fireEvent.click(screen.getByRole("button", { name: "Disable" }));
    const dialog = screen.getByRole("dialog", {
      name: "Disable kill-switch warnings_feature",
    });
    fireEvent.click(within(dialog).getByRole("button", { name: "Cancel" }));

    expect(toggleKillSwitch).not.toHaveBeenCalled();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchKillSwitches.mockRejectedValue(new Error("network"));
    renderPanel();

    await waitFor(() => {
      expect(screen.getByText("Could not load kill-switches")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
