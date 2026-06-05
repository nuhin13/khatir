import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { NotificationHistoryClient } from "@/app/(dashboard)/notifications/history/history_client";
import { describeAudience } from "@/components/admin/notification_history_table";
import type {
  Notification,
  NotificationDetail,
  NotificationDelivery,
} from "@/lib/api/notifications";

const fetchNotifications =
  vi.fn<(...args: unknown[]) => Promise<Notification[]>>();
const fetchNotificationDetail =
  vi.fn<(...args: unknown[]) => Promise<NotificationDetail>>();

vi.mock("@/lib/api/notifications", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/notifications")>(
      "@/lib/api/notifications",
    );
  return {
    ...actual,
    fetchNotifications: (...args: unknown[]) => fetchNotifications(...args),
    fetchNotificationDetail: (...args: unknown[]) =>
      fetchNotificationDetail(...args),
  };
});

function makeNotification(overrides: Partial<Notification> = {}): Notification {
  return {
    id: 7,
    sender: 1,
    audience_type: "all",
    audience_filter: {},
    channels: ["inapp", "whatsapp"],
    title_en: "Rent reminder",
    title_bn: "ভাড়ার স্মরণ",
    body_en: "Body",
    body_bn: "বডি",
    schedule_type: "now",
    scheduled_at: null,
    status: "sent",
    sent_count: 412,
    delivered_count: 400,
    opened_count: 120,
    created_at: "2026-06-05T10:00:00Z",
    updated_at: "2026-06-05T10:00:00Z",
    ...overrides,
  };
}

function makeDelivery(
  overrides: Partial<NotificationDelivery> = {},
): NotificationDelivery {
  return {
    id: 1,
    user: 42,
    channel: "whatsapp",
    status: "delivered",
    delivered_at: "2026-06-05T10:01:00Z",
    opened_at: null,
    error: null,
    created_at: "2026-06-05T10:00:30Z",
    updated_at: "2026-06-05T10:01:00Z",
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
  return render(<NotificationHistoryClient />, { wrapper });
}

describe("describeAudience", () => {
  it("describes each audience type", () => {
    expect(describeAudience(makeNotification({ audience_type: "all" }))).toBe(
      "All users",
    );
    expect(
      describeAudience(
        makeNotification({
          audience_type: "role",
          audience_filter: { role: "landlord" },
        }),
      ),
    ).toBe("Role: landlord");
    expect(
      describeAudience(
        makeNotification({
          audience_type: "specific",
          audience_filter: { user_ids: [1, 2, 3] },
        }),
      ),
    ).toBe("3 specific users");
  });
});

describe("NotificationHistoryClient", () => {
  beforeEach(() => {
    fetchNotifications.mockReset();
    fetchNotificationDetail.mockReset();
  });

  it("renders broadcasts with their counts and status", async () => {
    fetchNotifications.mockResolvedValue([makeNotification()]);
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Rent reminder")).toBeTruthy();
    });
    expect(screen.getByText("All users")).toBeTruthy();
    expect(screen.getByText("412")).toBeTruthy();
    expect(screen.getByText("400")).toBeTruthy();
    expect(screen.getByText("120")).toBeTruthy();
    expect(screen.getByText("sent")).toBeTruthy();
  });

  it("re-queries with the date filter when From changes", async () => {
    fetchNotifications.mockResolvedValue([makeNotification()]);
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Rent reminder")).toBeTruthy();
    });

    fireEvent.change(screen.getByLabelText("Filter from date"), {
      target: { value: "2026-06-01" },
    });

    await waitFor(() => {
      expect(fetchNotifications).toHaveBeenCalledWith(
        expect.objectContaining({ from: "2026-06-01" }),
      );
    });
  });

  it("expands a row and lazily fetches per-recipient deliveries", async () => {
    fetchNotifications.mockResolvedValue([makeNotification()]);
    fetchNotificationDetail.mockResolvedValue({
      ...makeNotification(),
      deliveries: [makeDelivery({ status: "opened", user: 99 })],
    });
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Rent reminder")).toBeTruthy();
    });

    expect(fetchNotificationDetail).not.toHaveBeenCalled();
    fireEvent.click(screen.getByRole("button", { name: "Show deliveries" }));

    await waitFor(() => {
      expect(fetchNotificationDetail).toHaveBeenCalledWith(7);
    });
    await waitFor(() => {
      expect(screen.getByText("opened")).toBeTruthy();
    });
    expect(screen.getByText("99")).toBeTruthy();
  });

  it("shows the empty state when there are no broadcasts", async () => {
    fetchNotifications.mockResolvedValue([]);
    renderPage();

    await waitFor(() => {
      expect(screen.getByText("No notifications")).toBeTruthy();
    });
  });

  it("shows an error state with a retry control when the fetch fails", async () => {
    fetchNotifications.mockRejectedValue(new Error("network"));
    renderPage();

    await waitFor(() => {
      expect(
        screen.getByText("Could not load notification history"),
      ).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });
});
