import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { useState } from "react";
import { AudienceSelector } from "@/components/admin/audience_selector";
import { ChannelSelector } from "@/components/admin/channel_selector";
import type {
  AudienceType,
  ChannelValue,
  CustomerRole,
} from "@/lib/api/notifications";

/**
 * EPIC-15.T-011 — reusable AudienceSelector + ChannelSelector widgets.
 * Render + interaction coverage for the controlled selectors.
 */

function ControlledAudience() {
  const [audienceType, setAudienceType] = useState<AudienceType>("all");
  const [roles, setRoles] = useState<CustomerRole[]>([]);
  const [userIds, setUserIds] = useState("");
  const toggleRole = (r: CustomerRole) =>
    setRoles((prev) =>
      prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r],
    );
  return (
    <AudienceSelector
      audienceType={audienceType}
      onAudienceType={setAudienceType}
      roles={roles}
      onToggleRole={toggleRole}
      userIds={userIds}
      onUserIds={setUserIds}
    />
  );
}

function ControlledChannels() {
  const [channels, setChannels] = useState<ChannelValue[]>(["inapp"]);
  const toggle = (c: ChannelValue) =>
    setChannels((prev) =>
      prev.includes(c) ? prev.filter((x) => x !== c) : [...prev, c],
    );
  return <ChannelSelector value={channels} onToggle={toggle} />;
}

describe("AudienceSelector", () => {
  it("renders all four audience-type radios", () => {
    render(<ControlledAudience />);
    expect(screen.getByRole("radio", { name: "All users" })).toBeTruthy();
    expect(screen.getByRole("radio", { name: "By role" })).toBeTruthy();
    expect(screen.getByRole("radio", { name: "By segment" })).toBeTruthy();
    expect(screen.getByRole("radio", { name: "Specific users" })).toBeTruthy();
  });

  it("shows the all-users note by default", () => {
    render(<ControlledAudience />);
    expect(
      screen.getByText(/reach every active user on the platform/),
    ).toBeTruthy();
  });

  it("reveals the role cohort chips when 'By role' is picked", () => {
    render(<ControlledAudience />);
    expect(screen.queryByText("Landlord")).toBeNull();
    fireEvent.click(screen.getByRole("radio", { name: "By role" }));
    const landlord = screen.getByText("Landlord");
    expect(landlord).toBeTruthy();
    // The radio reflects the selection.
    fireEvent.click(landlord);
    const cb = landlord.querySelector("input[type=checkbox]") as HTMLInputElement;
    expect(cb.checked).toBe(true);
  });

  it("reveals the user-ID search field for a specific audience", () => {
    render(<ControlledAudience />);
    fireEvent.click(screen.getByRole("radio", { name: "Specific users" }));
    const input = screen.getByPlaceholderText(
      "e.g. 1024, 1187, 2390",
    ) as HTMLTextAreaElement;
    fireEvent.change(input, { target: { value: "1, 2, 3" } });
    expect(input.value).toBe("1, 2, 3");
  });

  it("marks the active audience radio with aria-checked", () => {
    render(<ControlledAudience />);
    fireEvent.click(screen.getByRole("radio", { name: "By segment" }));
    expect(
      screen
        .getByRole("radio", { name: "By segment" })
        .getAttribute("aria-checked"),
    ).toBe("true");
  });
});

describe("ChannelSelector", () => {
  it("renders a checkbox per channel with cost chips", () => {
    render(<ControlledChannels />);
    expect(screen.getByText("In-app")).toBeTruthy();
    expect(screen.getByText("WhatsApp")).toBeTruthy();
    expect(screen.getByText("SMS")).toBeTruthy();
    expect(screen.getByText("Email")).toBeTruthy();
    // inapp + email are free.
    expect(screen.getAllByText("Free").length).toBe(2);
    // whatsapp + sms carry a per-message cost.
    expect(screen.getByText("৳0.5/msg")).toBeTruthy();
    expect(screen.getByText("৳0.3/msg")).toBeTruthy();
  });

  it("starts with in-app selected and toggles WhatsApp on/off", () => {
    render(<ControlledChannels />);
    const whatsapp = screen
      .getByText("WhatsApp")
      .closest("label")!
      .querySelector("input[type=checkbox]") as HTMLInputElement;
    expect(whatsapp.checked).toBe(false);
    fireEvent.click(whatsapp);
    expect(whatsapp.checked).toBe(true);
    fireEvent.click(whatsapp);
    expect(whatsapp.checked).toBe(false);
  });

  it("invokes onToggle with the channel value", () => {
    const onToggle = vi.fn();
    render(<ChannelSelector value={["inapp"]} onToggle={onToggle} />);
    fireEvent.click(
      screen
        .getByText("SMS")
        .closest("label")!
        .querySelector("input[type=checkbox]")!,
    );
    expect(onToggle).toHaveBeenCalledWith("sms");
  });
});
