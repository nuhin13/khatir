import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import {
  QueryClient,
  QueryClientProvider,
} from "@tanstack/react-query";
import type { ReactNode } from "react";
import DashboardPage from "@/app/(dashboard)/dashboard/page";
import type { Dashboard } from "@/lib/api/dashboard";

const fetchDashboard = vi.fn<() => Promise<Dashboard>>();

vi.mock("@/lib/api/dashboard", async () => {
  const actual = await vi.importActual<typeof import("@/lib/api/dashboard")>(
    "@/lib/api/dashboard",
  );
  return {
    ...actual,
    fetchDashboard: () => fetchDashboard(),
  };
});

function makeDashboard(overrides: Partial<Dashboard> = {}): Dashboard {
  return {
    total_users: 4832,
    active_landlords: 312,
    total_properties: 540,
    total_units: 1200,
    occupied_units: 980,
    total_rent_collected: { all_time: "14200000.00", this_month: "820000.00" },
    dmp_forms_generated: 1450,
    active_subscriptions: 290,
    health: { app: "ok", database: "ok", cache: "ok", status: "ok" },
    recent_activity: [],
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
  return render(<DashboardPage />, { wrapper });
}

describe("DashboardPage", () => {
  beforeEach(() => {
    fetchDashboard.mockReset();
  });

  it("renders the platform KPI tiles from the API", async () => {
    fetchDashboard.mockResolvedValue(makeDashboard());
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Total users")).toBeTruthy();
    });
    expect(screen.getByText("4,832")).toBeTruthy();
    expect(screen.getByText("Active landlords")).toBeTruthy();
    expect(screen.getByText("DMP forms generated")).toBeTruthy();
    expect(screen.getByText("Active subscriptions")).toBeTruthy();
  });

  it("renders the activity feed with audit entries", async () => {
    fetchDashboard.mockResolvedValue(
      makeDashboard({
        recent_activity: [
          {
            id: 1,
            action: "Subscription",
            actor: "Md. Ibrahim",
            summary: "upgraded to Bundle 20",
            created_at: "2026-06-05T10:00:00Z",
          },
        ],
      }),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Recent activity")).toBeTruthy();
    });
    expect(screen.getByText("Subscription")).toBeTruthy();
    expect(screen.getByText("Md. Ibrahim")).toBeTruthy();
  });

  it("shows the activity empty state when there are no entries", async () => {
    fetchDashboard.mockResolvedValue(makeDashboard());
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("No recent activity yet.")).toBeTruthy();
    });
  });

  it("renders the system-health panel", async () => {
    fetchDashboard.mockResolvedValue(
      makeDashboard({
        health: { app: "ok", database: "down", cache: "ok", status: "degraded" },
      }),
    );
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("System health")).toBeTruthy();
    });
    expect(screen.getByText("Database")).toBeTruthy();
    expect(screen.getByText("DOWN")).toBeTruthy();
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchDashboard.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Could not load dashboard")).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
