import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { NotificationTemplates } from "@/components/admin/notification_templates";
import type {
  NotificationTemplate,
  TemplateUpdateInput,
} from "@/lib/api/notifications";

const fetchTemplates = vi.fn<() => Promise<NotificationTemplate[]>>();
const updateTemplate =
  vi.fn<(key: string, input: TemplateUpdateInput) => Promise<NotificationTemplate>>();

vi.mock("@/lib/api/notifications", async () => {
  const actual =
    await vi.importActual<typeof import("@/lib/api/notifications")>(
      "@/lib/api/notifications",
    );
  return {
    ...actual,
    fetchTemplates: () => fetchTemplates(),
    updateTemplate: (key: string, input: TemplateUpdateInput) =>
      updateTemplate(key, input),
  };
});

function makeTemplate(
  overrides: Partial<NotificationTemplate> = {},
): NotificationTemplate {
  return {
    id: 1,
    key: "rent_reminder_due",
    trigger_event: "rent_due",
    channels: ["whatsapp", "sms"],
    title_en: "Rent due",
    title_bn: "ভাড়া বাকি",
    body_en: "Hi {tenant_name}, your rent is due.",
    body_bn: "হ্যালো {tenant_name}, ভাড়া বাকি।",
    variables: ["tenant_name", "amount"],
    active: true,
    created_at: "2026-06-05T00:00:00Z",
    updated_at: "2026-06-05T00:00:00Z",
    ...overrides,
  };
}

function renderTemplates() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return render(<NotificationTemplates />, { wrapper });
}

describe("NotificationTemplates", () => {
  beforeEach(() => {
    fetchTemplates.mockReset();
    updateTemplate.mockReset();
  });

  it("lists templates with key, trigger event, channels and active state", async () => {
    fetchTemplates.mockResolvedValue([
      makeTemplate(),
      makeTemplate({
        id: 2,
        key: "welcome_new_user",
        trigger_event: "user_created",
        channels: ["inapp"],
        title_en: "Welcome",
        active: false,
      }),
    ]);
    renderTemplates();

    await waitFor(() => {
      expect(screen.getByText("rent_reminder_due")).toBeTruthy();
    });
    expect(screen.getByText("welcome_new_user")).toBeTruthy();
    expect(screen.getByText("rent_due")).toBeTruthy();
    expect(screen.getAllByText("Active").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Inactive").length).toBeGreaterThan(0);
  });

  it("renders an error state with a retry action", async () => {
    fetchTemplates.mockRejectedValue(new Error("boom"));
    renderTemplates();

    await waitFor(() => {
      expect(
        screen.getByText(/Could not load notification templates/),
      ).toBeTruthy();
    });
    expect(screen.getByRole("button", { name: "Retry" })).toBeTruthy();
  });

  it("opens the editor showing the immutable trigger event and variables", async () => {
    fetchTemplates.mockResolvedValue([makeTemplate()]);
    renderTemplates();

    await waitFor(() => {
      expect(screen.getByText("rent_reminder_due")).toBeTruthy();
    });
    fireEvent.click(
      screen.getByRole("button", { name: "Edit rent_reminder_due" }),
    );

    const dialog = screen.getByRole("dialog");
    expect(dialog).toBeTruthy();
    // Trigger event shown read-only (no input field for it).
    expect(screen.getByText("Trigger event (fixed)")).toBeTruthy();
    // Variable reference rendered as chips.
    expect(screen.getByText("{tenant_name}")).toBeTruthy();
    expect(screen.getByText("{amount}")).toBeTruthy();
  });

  it("saves edited fields without ever sending key or trigger_event", async () => {
    fetchTemplates.mockResolvedValue([makeTemplate()]);
    updateTemplate.mockResolvedValue(makeTemplate({ title_en: "Rent overdue" }));
    renderTemplates();

    await waitFor(() => {
      expect(screen.getByText("rent_reminder_due")).toBeTruthy();
    });
    fireEvent.click(
      screen.getByRole("button", { name: "Edit rent_reminder_due" }),
    );

    const titleEn = screen.getByDisplayValue("Rent due");
    fireEvent.change(titleEn, { target: { value: "Rent overdue" } });
    fireEvent.click(screen.getByRole("button", { name: "Save template" }));

    await waitFor(() => {
      expect(updateTemplate).toHaveBeenCalledTimes(1);
    });
    const [key, input] = updateTemplate.mock.calls[0];
    expect(key).toBe("rent_reminder_due");
    expect(input.title_en).toBe("Rent overdue");
    expect(input).not.toHaveProperty("key");
    expect(input).not.toHaveProperty("trigger_event");

    // Editor closes on success.
    await waitFor(() => {
      expect(screen.queryByRole("dialog")).toBeNull();
    });
  });

  it("blocks save when a required content field is cleared", async () => {
    fetchTemplates.mockResolvedValue([makeTemplate()]);
    renderTemplates();

    await waitFor(() => {
      expect(screen.getByText("rent_reminder_due")).toBeTruthy();
    });
    fireEvent.click(
      screen.getByRole("button", { name: "Edit rent_reminder_due" }),
    );

    fireEvent.change(screen.getByDisplayValue("Rent due"), {
      target: { value: "" },
    });
    const save = screen.getByRole("button", {
      name: "Save template",
    }) as HTMLButtonElement;
    expect(save.disabled).toBe(true);
  });

  it("surfaces an error when the save request fails", async () => {
    fetchTemplates.mockResolvedValue([makeTemplate()]);
    updateTemplate.mockRejectedValue(new Error("boom"));
    renderTemplates();

    await waitFor(() => {
      expect(screen.getByText("rent_reminder_due")).toBeTruthy();
    });
    fireEvent.click(
      screen.getByRole("button", { name: "Edit rent_reminder_due" }),
    );
    fireEvent.click(screen.getByRole("button", { name: "Save template" }));

    await waitFor(() => {
      expect(screen.getByText(/Could not save the template/)).toBeTruthy();
    });
  });
});
