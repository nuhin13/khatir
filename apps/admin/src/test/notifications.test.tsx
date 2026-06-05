import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { NotificationComposer } from "@/components/admin/notification_composer";
import {
  estimateCost,
  type ComposeInput,
  type ComposeResult,
} from "@/lib/api/notifications";

const composeNotification = vi.fn<(input: ComposeInput) => Promise<ComposeResult>>();

vi.mock("@/lib/api/notifications", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/notifications")>(
      "@/lib/api/notifications",
    );
  return {
    ...actual,
    composeNotification: (input: ComposeInput) => composeNotification(input),
  };
});

function makeResult(overrides: Partial<ComposeResult> = {}): ComposeResult {
  return {
    id: 7,
    sender: 1,
    audience_type: "all",
    audience_filter: {},
    channels: ["inapp", "whatsapp"],
    title_en: "Hi",
    title_bn: "হাই",
    body_en: "Body",
    body_bn: "বডি",
    schedule_type: "now",
    scheduled_at: null,
    status: "sending",
    sent_count: 0,
    delivered_count: 0,
    opened_count: 0,
    created_at: "2026-06-05T00:00:00Z",
    updated_at: "2026-06-05T00:00:00Z",
    reach: 412,
    estimated_cost: "206.00",
    ...overrides,
  };
}

function renderComposer() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<NotificationComposer />, { wrapper });
}

/** Fill the four required bilingual content fields. */
function fillContent() {
  fireEvent.change(screen.getByPlaceholderText("e.g. Your rent is due"), {
    target: { value: "Rent due" },
  });
  fireEvent.change(screen.getByPlaceholderText("যেমন আপনার ভাড়া বাকি"), {
    target: { value: "ভাড়া বাকি" },
  });
  fireEvent.change(
    screen.getByPlaceholderText("Hi {name}, your rent for {unit} is due."),
    { target: { value: "Hello {name}" } },
  );
  fireEvent.change(
    screen.getByPlaceholderText("হ্যালো {name}, {unit} এর ভাড়া বাকি।"),
    { target: { value: "হ্যালো" } },
  );
}

describe("estimateCost", () => {
  it("charges only the paid channels (whatsapp + sms), free for inapp/email", () => {
    expect(estimateCost(412, ["inapp", "whatsapp"])).toBeCloseTo(206);
    expect(estimateCost(100, ["inapp", "email"])).toBe(0);
    expect(estimateCost(10, ["sms"])).toBeCloseTo(3);
  });
});

describe("NotificationComposer", () => {
  beforeEach(() => {
    composeNotification.mockReset();
  });

  it("renders the audience, channels, message and schedule sections", () => {
    renderComposer();
    expect(screen.getByText("Audience")).toBeTruthy();
    expect(screen.getByText("Channels")).toBeTruthy();
    expect(screen.getByText("Message")).toBeTruthy();
    expect(screen.getByText("Schedule")).toBeTruthy();
    expect(screen.getByRole("radio", { name: "All users" })).toBeTruthy();
  });

  it("blocks submit until required content is filled", () => {
    renderComposer();
    const send = screen.getByRole("button", { name: "Send notification" });
    expect((send as HTMLButtonElement).disabled).toBe(true);

    fillContent();
    expect((send as HTMLButtonElement).disabled).toBe(false);
  });

  it("inserts a variable chip into the English body", () => {
    renderComposer();
    const body = screen.getByPlaceholderText(
      "Hi {name}, your rent for {unit} is due.",
    ) as HTMLTextAreaElement;
    fireEvent.change(body, { target: { value: "Hi " } });
    // The {name} chip appears once per body (en + bn) — click the first.
    fireEvent.click(screen.getAllByRole("button", { name: "{name}" })[0]);
    expect(body.value).toContain("{name}");
  });

  it("shows the explicit reach + cost for a specific-user audience", () => {
    renderComposer();
    fireEvent.click(screen.getByRole("radio", { name: "Specific users" }));
    fireEvent.change(screen.getByPlaceholderText("e.g. 1024, 1187, 2390"), {
      target: { value: "1, 2, 3, 4" },
    });
    // inapp is the default channel (free) → reach 4, cost ৳0.
    expect(screen.getByText("4")).toBeTruthy();
  });

  it("composes a broadcast and shows the server reach + cost on success", async () => {
    composeNotification.mockResolvedValue(makeResult());
    renderComposer();
    fillContent();
    // Add WhatsApp so a paid channel is included.
    fireEvent.click(screen.getByText("WhatsApp"));
    fireEvent.click(screen.getByRole("button", { name: "Send notification" }));

    await waitFor(() => {
      expect(composeNotification).toHaveBeenCalledTimes(1);
    });
    const input = composeNotification.mock.calls[0][0];
    expect(input.audience_type).toBe("all");
    expect(input.channels).toContain("whatsapp");
    expect(input.schedule_type).toBe("now");

    await waitFor(() => {
      expect(screen.getByText("412")).toBeTruthy();
    });
    expect(screen.getByText("৳206")).toBeTruthy();
  });

  it("requires a role selection for a by-role audience", () => {
    renderComposer();
    fillContent();
    fireEvent.click(screen.getByRole("radio", { name: "By role" }));
    const send = screen.getByRole("button", { name: "Send notification" });
    expect((send as HTMLButtonElement).disabled).toBe(true);

    fireEvent.click(screen.getByText("Landlord"));
    expect((send as HTMLButtonElement).disabled).toBe(false);
  });

  it("surfaces an error when the compose request fails", async () => {
    composeNotification.mockRejectedValue(new Error("boom"));
    renderComposer();
    fillContent();
    fireEvent.click(screen.getByRole("button", { name: "Send notification" }));

    await waitFor(() => {
      expect(
        screen.getByText(/Could not send the notification/),
      ).toBeTruthy();
    });
  });
});
