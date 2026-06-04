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
import { FlagsConsole } from "@/components/admin/flags_console";
import type { FeatureFlag } from "@/lib/api/flags";

const fetchFeatureFlags = vi.fn<() => Promise<FeatureFlag[]>>();
const toggleFeatureFlag = vi.fn<() => Promise<FeatureFlag>>();

vi.mock("@/lib/api/flags", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/flags")>("@/lib/api/flags");
  return {
    ...actual,
    fetchFeatureFlags: () => fetchFeatureFlags(),
    toggleFeatureFlag: () => toggleFeatureFlag(),
  };
});

function makeFlag(overrides: Partial<FeatureFlag> = {}): FeatureFlag {
  return {
    id: 1,
    key: "nid_verification",
    description: "EC NID Matched/Not Matched verification",
    scope: "global",
    enabled: false,
    value_json: null,
    updated_by: null,
    created_at: "2026-06-01T00:00:00Z",
    updated_at: "2026-06-01T00:00:00Z",
    ...overrides,
  };
}

function renderConsole() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<FlagsConsole />, { wrapper });
}

describe("FlagsConsole", () => {
  beforeEach(() => {
    fetchFeatureFlags.mockReset();
    toggleFeatureFlag.mockReset();
  });

  it("renders the flag rows from the API (key, scope, status)", async () => {
    fetchFeatureFlags.mockResolvedValue([
      makeFlag(),
      makeFlag({ id: 2, key: "voice_form_fill", enabled: true }),
    ]);
    renderConsole();

    await waitFor(() => {
      expect(screen.getByText("nid_verification")).toBeTruthy();
    });
    expect(screen.getByText("voice_form_fill")).toBeTruthy();
    expect(screen.getByText("On")).toBeTruthy();
    expect(screen.getByText("Off")).toBeTruthy();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchFeatureFlags.mockRejectedValue(new Error("network"));
    renderConsole();

    await waitFor(() => {
      expect(screen.getByText("Could not load feature flags")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("opens a confirm dialog on toggle and does not call the API until confirmed", async () => {
    fetchFeatureFlags.mockResolvedValue([makeFlag()]);
    renderConsole();

    await waitFor(() => {
      expect(screen.getByText("nid_verification")).toBeTruthy();
    });

    fireEvent.click(
      screen.getByRole("switch", { name: "Toggle nid_verification" }),
    );

    // a confirm dialog opens; the toggle endpoint has NOT been called yet
    const dialog = screen.getByRole("dialog", {
      name: "Toggle flag nid_verification",
    });
    expect(dialog).toBeTruthy();
    expect(toggleFeatureFlag).not.toHaveBeenCalled();

    // confirming fires the toggle mutation
    toggleFeatureFlag.mockResolvedValue(makeFlag({ enabled: true }));
    fireEvent.click(within(dialog).getByRole("button", { name: "Enable flag" }));

    await waitFor(() => {
      expect(toggleFeatureFlag).toHaveBeenCalledTimes(1);
    });
  });

  it("cancelling the confirm dialog never calls the toggle endpoint", async () => {
    fetchFeatureFlags.mockResolvedValue([makeFlag({ enabled: true })]);
    renderConsole();

    await waitFor(() => {
      expect(screen.getByText("nid_verification")).toBeTruthy();
    });

    fireEvent.click(
      screen.getByRole("switch", { name: "Toggle nid_verification" }),
    );
    const dialog = screen.getByRole("dialog", {
      name: "Toggle flag nid_verification",
    });
    // an enabled flag offers a Disable action
    fireEvent.click(within(dialog).getByRole("button", { name: "Cancel" }));

    expect(toggleFeatureFlag).not.toHaveBeenCalled();
  });
});
